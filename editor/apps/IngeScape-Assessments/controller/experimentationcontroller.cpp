/*
 *	IngeScape Assessments
 *
 *  Copyright © 2019 Ingenuity i/o. All rights reserved.
 *
 *	See license terms for the rights and conditions
 *	defined by copyright holders.
 *
 *
 *	Contributors:
 *      Vincent Peyruqueou <peyruqueou@ingenuity.io>
 *
 */

#include "experimentationcontroller.h"

#include <ctime>

#include <controller/assessmentsmodelmanager.h>

/**
 * @brief Constructor
 * @param modelManager
 * @param jsonHelper
 * @param parent
 */
ExperimentationController::ExperimentationController(JsonHelper* jsonHelper,
                                                     QObject *parent) : QObject(parent),
    _recordC(nullptr),
    _currentExperimentation(nullptr),
    _jsonHelper(jsonHelper)
{
    // Force ownership of our object, it will prevent Qml from stealing it
    QQmlEngine::setObjectOwnership(this, QQmlEngine::CppOwnership);

    qInfo() << "New Experimentation Controller";

    // Create the controller to manage a record of the current experimentation
    _recordC = new RecordController(_jsonHelper, this);
}


/**
 * @brief Destructor
 */
ExperimentationController::~ExperimentationController()
{
    qInfo() << "Delete Experimentation Controller";

    // Reset the model of the current experimentation
    if (_currentExperimentation != nullptr)
    {
        setcurrentExperimentation(nullptr);
    }

    if (_recordC != nullptr)
    {
        disconnect(_recordC);

        RecordController* temp = _recordC;
        setrecordC(nullptr);
        delete temp;
        temp = nullptr;
    }

    /*if (_modelManager != nullptr)
    {
        disconnect(_modelManager, nullptr, this, nullptr);

        _modelManager = nullptr;
    }*/

    // Reset pointers
    _jsonHelper = nullptr;
}


/**
 * @brief Setter for property "Current Experimentation"
 * @param value
 */
void ExperimentationController::setcurrentExperimentation(ExperimentationM *value)
{
    if (_currentExperimentation != value)
    {
        if (_currentExperimentation != nullptr)
        {
            // Unload any previous experimentation
            _currentExperimentation->clearData();
        }

        _currentExperimentation = value;

        // Manage changes
        _onCurrentExperimentationChanged(_currentExperimentation);

        Q_EMIT currentExperimentationChanged(value);
    }
}


/**
 * @brief Create a new record for a subject and a task
 * @param recordName
 * @param subject
 * @param task
 */
void ExperimentationController::createNewRecordForSubjectAndTask(QString recordName, SubjectM* subject, TaskM* task)
{
    if (!recordName.isEmpty() && (subject != nullptr) && (task != nullptr) && (_currentExperimentation != nullptr))
    {
        qInfo() << "Create new record" << recordName << "for subject" << subject->displayedId() << "and task" << task->name();

        // Create a new (experimentation) record setup
        RecordSetupM* recordSetup = _insertRecordSetupIntoDB(recordName, subject, task);

        if (recordSetup != nullptr)
        {
            // Add the record to the current experimentation
            _currentExperimentation->addRecordSetup(recordSetup);

            // Open this new record
            openRecordSetup(recordSetup);
        }
    }
}


/**
 * @brief Open a record setup
 * @param record
 */
void ExperimentationController::openRecordSetup(RecordSetupM* recordSetup)
{
    if ((recordSetup != nullptr) && (_currentExperimentation != nullptr))
    {
        qInfo() << "Open the record" << recordSetup->name() << "of the experimentation" << _currentExperimentation->name();

        // Update the current record setup
        _recordC->setcurrentRecordSetup(recordSetup);
    }
}


/**
 * @brief Delete a record setup
 * @param record
 */
void ExperimentationController::deleteRecordSetup(RecordSetupM* recordSetup)
{
    if ((recordSetup != nullptr) && (_currentExperimentation != nullptr))
    {
        qInfo() << "Delete the record" << recordSetup->name() << "of the experimentation" << _currentExperimentation->name();

        // Remove the record from the current experimentation
        _currentExperimentation->removeRecordSetup(recordSetup);

        // Free memory
        delete recordSetup;
    }
}


/**
 * @brief Slot called when the current experimentation changed
 * @param currentExperimentation
 */
void ExperimentationController::_onCurrentExperimentationChanged(ExperimentationM* currentExperimentation)
{
    if (currentExperimentation != nullptr && AssessmentsModelManager::Instance() != nullptr)
    {
        qDebug() << "_on Current Experimentation Changed" << currentExperimentation->name();

        // FIXME TODO: load data about this experimentation (subjects, tasks, ...)

        _retrieveTasksForExperimentation(currentExperimentation);

        _retrieveSubjectsForExperimentation(currentExperimentation);

        _retrieveCharacteristicsForExperimentation(currentExperimentation);

        _retrieveCharacteristicValuesForSubjectsInExperimentation(currentExperimentation);
    }
}

/**
 * @brief Create and insert a new record setup into the DB.
 * A nullptr is returned if the record setup could not be created
 * @param recordName
 * @param subject
 * @param task
 * @return
 */
RecordSetupM* ExperimentationController::_insertRecordSetupIntoDB(const QString& recordName, SubjectM* subject, TaskM* task)
{
    RecordSetupM* recordSetup = nullptr;

    if ((_currentExperimentation != nullptr) && (subject != nullptr) && (task != nullptr))
    {
        CassUuid recordSetupUuid;
        cass_uuid_gen_time(AssessmentsModelManager::Instance()->getCassUuidGen(), &recordSetupUuid);

        time_t now = std::time(nullptr);

        cass_uint32_t yearMonthDay = cass_date_from_epoch(now);
        cass_int64_t timeOfDay = cass_time_from_epoch(now);

        CassUuid recordUuid;
        cass_uuid_from_string("052c42a0-ad26-11e9-bd79-c9fd40f1d28a", &recordUuid);

        //const char* query = "INSERT INTO ingescape.record_setup (id_experimentation, id_subject, id_task, id, name, start_date, start_time, end_date, end_time) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?);";
        const char* query = "INSERT INTO ingescape.record_setup (id, id_experimentation, id_subject, id_task, id_records, name, start_date, start_time, end_date, end_time) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?);";
        CassStatement* cassStatement = cass_statement_new(query, 10);
        cass_statement_bind_uuid  (cassStatement, 0, recordSetupUuid);
        cass_statement_bind_uuid  (cassStatement, 1, _currentExperimentation->getCassUuid());
        cass_statement_bind_uuid  (cassStatement, 2, subject->getCassUuid());
        cass_statement_bind_uuid  (cassStatement, 3, task->getCassUuid());
        cass_statement_bind_uuid  (cassStatement, 4, recordUuid);
        cass_statement_bind_string(cassStatement, 5, recordName.toStdString().c_str());
        cass_statement_bind_uint32(cassStatement, 6, yearMonthDay);
        cass_statement_bind_int64 (cassStatement, 7, timeOfDay);
        cass_statement_bind_uint32(cassStatement, 8, yearMonthDay); //FIXME current date/time to have all values filled with something for test purposes.
        cass_statement_bind_int64 (cassStatement, 9, timeOfDay); //FIXME current date/time to have all values filled with something for test purposes.

        // Execute the query or bound statement
        CassFuture* cassFuture = cass_session_execute(AssessmentsModelManager::Instance()->getCassSession(), cassStatement);
        CassError cassError = cass_future_error_code(cassFuture);
        if (cassError == CASS_OK)
        {
            qInfo() << "New dependent variable inserted into the DB";

            // Create the new record setup
            recordSetup = new RecordSetupM(recordSetupUuid, recordName, subject, task, QDateTime::currentDateTime());
        }
        else {
            qCritical() << "Could not insert the new dependent variable into the DB:" << cass_error_desc(cassError);
        }

        cass_statement_free(cassStatement);
        cass_future_free(cassFuture);
    }

    return recordSetup;
}

/**
 * @brief Retrieve all independent variables from the Cassandra DB for the given task.
 * The task will be updated by this method
 * @param task
 */
void ExperimentationController::_retrieveIndependentVariableForTask(TaskM* task)
{
    if (AssessmentsModelManager::Instance() != nullptr)
    {
        const char* query = "SELECT * FROM ingescape.independent_var WHERE id_experimentation = ? AND id_task = ?;";

        // Creates the new query statement
        CassStatement* cassStatement = cass_statement_new(query, 2);
        cass_statement_bind_uuid(cassStatement, 0, task->getExperimentationCassUuid());
        cass_statement_bind_uuid(cassStatement, 1, task->getCassUuid());
        // Execute the query or bound statement
        CassFuture* cassFuture = cass_session_execute(AssessmentsModelManager::Instance()->getCassSession(), cassStatement);
        CassError cassError = cass_future_error_code(cassFuture);
        if (cassError == CASS_OK)
        {
            qDebug() << "Get all independent variables for task" << task->name() << "succeeded";
        }
        else {
            qCritical() << "Could not get all independent variables for task" << task->name() << "from the database:" << cass_error_desc(cassError);
        }

        // Retrieve result set and iterate over the rows
        const CassResult* cassResult = cass_future_get_result(cassFuture);
        if (cassResult != nullptr)
        {
            CassIterator* cassIterator = cass_iterator_from_result(cassResult);

            while(cass_iterator_next(cassIterator))
            {
                const CassRow* row = cass_iterator_get_row(cassIterator);
                IndependentVariableM* independentVariable = IndependentVariableM::createIndependentVariableFromCassandraRow(row);
                if (independentVariable != nullptr)
                {
                    task->addIndependentVariable(independentVariable);
                }
            }

            cass_iterator_free(cassIterator);
        }

        cass_future_free(cassFuture);
        cass_statement_free(cassStatement);
    }
}

/**
 * @brief Retrieve all dependent variables from the Cassandra DB for the given task.
 * The task will be updated by this method.
 * @param task
 */
void ExperimentationController::_retrieveDependentVariableForTask(TaskM* task)
{
    if ((task != nullptr) && (AssessmentsModelManager::Instance() != nullptr))
    {
        const char* query = "SELECT * FROM ingescape.dependent_var WHERE id_experimentation = ? AND id_task = ?;";

        // Creates the new query statement
        CassStatement* cassStatement = cass_statement_new(query, 2);
        cass_statement_bind_uuid(cassStatement, 0, task->getExperimentationCassUuid());
        cass_statement_bind_uuid(cassStatement, 1, task->getCassUuid());
        // Execute the query or bound statement
        CassFuture* cassFuture = cass_session_execute(AssessmentsModelManager::Instance()->getCassSession(), cassStatement);
        CassError cassError = cass_future_error_code(cassFuture);
        if (cassError == CASS_OK)
        {
            qDebug() << "Get all independent variables for task" << task->name() << "succeeded";
        }
        else {
            qCritical() << "Could not get all independent variables for task" << task->name() << "from the database:" << cass_error_desc(cassError);
        }

        // Retrieve result set and iterate over the rows
        const CassResult* cassResult = cass_future_get_result(cassFuture);
        if (cassResult != nullptr)
        {
            CassIterator* cassIterator = cass_iterator_from_result(cassResult);

            while(cass_iterator_next(cassIterator))
            {
                const CassRow* row = cass_iterator_get_row(cassIterator);
                DependentVariableM* dependentVariable = DependentVariableM::createDependentVariableFromCassandraRow(row);
                if (dependentVariable != nullptr)
                {
                    task->addDependentVariable(dependentVariable);
                }
            }

            cass_iterator_free(cassIterator);
        }

        cass_future_free(cassFuture);
        cass_statement_free(cassStatement);
    }
}


/**
 * @brief Retrieve all subjects from the Cassandra DB for the given experimentaion.
 * The experimentation will be updated by this method
 * @param experimentation
 */
void ExperimentationController::_retrieveSubjectsForExperimentation(ExperimentationM* experimentation)
{
    if (experimentation != nullptr)
    {
        const char* query = "SELECT * FROM ingescape.subject WHERE id_experimentation = ?;";

        // Creates the new query statement
        CassStatement* cassStatement = cass_statement_new(query, 1);
        cass_statement_bind_uuid(cassStatement, 0, experimentation->getCassUuid());

        // Execute the query or bound statement
        CassFuture* cassFuture = cass_session_execute(AssessmentsModelManager::Instance()->getCassSession(), cassStatement);
        CassError cassError = cass_future_error_code(cassFuture);
        if (cassError == CASS_OK)
        {
            qDebug() << "Get all subjects succeeded";

            // Retrieve result set and iterate over the rows
            const CassResult* cassResult = cass_future_get_result(cassFuture);

            if (cassResult != nullptr)
            {
                CassIterator* cassIterator = cass_iterator_from_result(cassResult);

                while(cass_iterator_next(cassIterator))
                {
                    const CassRow* row = cass_iterator_get_row(cassIterator);
                    SubjectM* subject = SubjectM::createTaskFromCassandraRow(row);
                    if (subject != nullptr)
                    {
                        // Add the subject to the experimentation
                        experimentation->addSubject(subject);
                    }
                }

                cass_iterator_free(cassIterator);
            }
        }
        else {
            qCritical() << "Could not get all subjects for the current experiment from the database:" << cass_error_desc(cassError);
        }

        cass_future_free(cassFuture);
        cass_statement_free(cassStatement);
    }
}


/**
 * @brief Retrieve all characteristics from the Cassandra DB for the given experimentaion.
 * The experimentation will be updated by this method
 * @param experimentation
 */
void ExperimentationController::_retrieveCharacteristicsForExperimentation(ExperimentationM* experimentation)
{
    if (experimentation != nullptr)
    {
        const char* query = "SELECT * FROM ingescape.characteristic WHERE id_experimentation = ?;";

        // Creates the new query statement
        CassStatement* cassStatement = cass_statement_new(query, 1);
        cass_statement_bind_uuid(cassStatement, 0, experimentation->getCassUuid());

        // Execute the query or bound statement
        CassFuture* cassFuture = cass_session_execute(AssessmentsModelManager::Instance()->getCassSession(), cassStatement);
        CassError cassError = cass_future_error_code(cassFuture);
        if (cassError == CASS_OK)
        {
            qDebug() << "Get all characteristics succeeded";

            // Retrieve result set and iterate over the rows
            const CassResult* cassResult = cass_future_get_result(cassFuture);

            if (cassResult != nullptr)
            {
                CassIterator* cassIterator = cass_iterator_from_result(cassResult);

                while(cass_iterator_next(cassIterator))
                {
                    const CassRow* row = cass_iterator_get_row(cassIterator);
                    CharacteristicM* characteristic = CharacteristicM::createCharacteristicFromCassandraRow(row);
                    if (characteristic != nullptr)
                    {
                        // Add the characteristic to the experimentation
                        experimentation->addCharacteristic(characteristic);
                    }
                }

                cass_iterator_free(cassIterator);
            }
        }
        else {
            qCritical() << "Could not get all tasks for the current experiment from the database:" << cass_error_desc(cassError);
        }

        cass_future_free(cassFuture);
        cass_statement_free(cassStatement);
    }
}


/**
 * @brief Retrieve all tasks from the Cassandra DB for the given experimentaion.
 * The experimentation will be updated by this method
 * @param experimentation
 */
void ExperimentationController::_retrieveTasksForExperimentation(ExperimentationM* experimentation)
{
    if (experimentation != nullptr)
    {
        const char* query = "SELECT * FROM ingescape.task WHERE id_experimentation = ?;";

        // Creates the new query statement
        CassStatement* cassStatement = cass_statement_new(query, 1);
        cass_statement_bind_uuid(cassStatement, 0, experimentation->getCassUuid());

        // Execute the query or bound statement
        CassFuture* cassFuture = cass_session_execute(AssessmentsModelManager::Instance()->getCassSession(), cassStatement);
        CassError cassError = cass_future_error_code(cassFuture);
        if (cassError == CASS_OK)
        {
            qDebug() << "Get all tasks succeeded";

            // Retrieve result set and iterate over the rows
            const CassResult* cassResult = cass_future_get_result(cassFuture);

            if (cassResult != nullptr)
            {
                CassIterator* cassIterator = cass_iterator_from_result(cassResult);

                while(cass_iterator_next(cassIterator))
                {
                    const CassRow* row = cass_iterator_get_row(cassIterator);
                    TaskM* task = TaskM::createTaskFromCassandraRow(row);
                    if (task != nullptr)
                    {
                        // Load variables
                        _retrieveIndependentVariableForTask(task);

                        // Load variables
                        _retrieveDependentVariableForTask(task);

                        // Add the task to the experimentation
                        experimentation->addTask(task);
                    }
                }

                cass_iterator_free(cassIterator);
            }
        }
        else {
            qCritical() << "Could not get all tasks for the current experiment from the database:" << cass_error_desc(cassError);
        }

        cass_future_free(cassFuture);
        cass_statement_free(cassStatement);
    }
}

void ExperimentationController::_retrieveCharacteristicValuesForSubjectsInExperimentation(ExperimentationM* experimentation)
{
    if (experimentation != nullptr)
    {
        for (auto subjectIt = experimentation->allSubjects()->begin() ; subjectIt != experimentation->allSubjects()->end() ; ++subjectIt)
        {
            SubjectM* subject = *subjectIt;
            if (subject != nullptr)
            {
                const char* query = "SELECT * FROM ingescape.characteristic_value_of_subject WHERE id_experimentation = ? AND id_subject = ?;";

                // Creates the new query statement
                CassStatement* cassStatement = cass_statement_new(query, 2);
                cass_statement_bind_uuid(cassStatement, 0, experimentation->getCassUuid());
                cass_statement_bind_uuid(cassStatement, 1, subject->getCassUuid());

                // Execute the query or bound statement
                CassFuture* cassFuture = cass_session_execute(AssessmentsModelManager::Instance()->getCassSession(), cassStatement);
                CassError cassError = cass_future_error_code(cassFuture);
                if (cassError == CASS_OK)
                {
                    qDebug() << "Get all characteristics values for subject" << subject->displayedId() << "succeeded";

                    // Retrieve result set and iterate over the rows
                    const CassResult* cassResult = cass_future_get_result(cassFuture);

                    if (cassResult != nullptr)
                    {
                        CassIterator* cassIterator = cass_iterator_from_result(cassResult);

                        while(cass_iterator_next(cassIterator))
                        {
                            const CassRow* row = cass_iterator_get_row(cassIterator);

                            // Get characteristic id
                            CassUuid characteristicUuid;
                            cass_value_get_uuid(cass_row_get_column_by_name(row, "id_characteristic"), &characteristicUuid);
                            char chrCharacteristicUid[CASS_UUID_STRING_LENGTH];
                            cass_uuid_string(characteristicUuid, chrCharacteristicUid);

                            // Get characteristic value as a string
                            const char *chrValueString = "";
                            size_t valueStringLength = 0;
                            cass_value_get_string(cass_row_get_column_by_name(row, "characteristic_value"), &chrValueString, &valueStringLength);
                            QString valueString = QString::fromUtf8(chrValueString, static_cast<int>(valueStringLength));


                            // Get characteristic value type
                            CharacteristicM* characteristic = _currentExperimentation->getCharacteristicFromUID(chrCharacteristicUid);
                            if (characteristic != nullptr)
                            {
                                switch (characteristic->valueType()) {
                                    case CharacteristicValueTypes::INTEGER:
                                        subject->setCharacteristicValue(characteristic, valueString.toInt());
                                        break;
                                    case CharacteristicValueTypes::DOUBLE:
                                        subject->setCharacteristicValue(characteristic, valueString.toDouble());
                                        break;
                                    case CharacteristicValueTypes::TEXT:
                                        subject->setCharacteristicValue(characteristic, valueString);
                                        break;
                                    case CharacteristicValueTypes::CHARACTERISTIC_ENUM:
                                        subject->setCharacteristicValue(characteristic, valueString);
                                        break;
                                    default: // UNKNOWN
                                        break;
                                }
                            }

                        }

                        cass_iterator_free(cassIterator);
                    }
                }
                else {
                    qCritical() << "Could not get all characteristic values for the subjects of experiment" << experimentation->name() << "from the database:" << cass_error_desc(cassError);
                }

                cass_future_free(cassFuture);
                cass_statement_free(cassStatement);
            }
        }
    }
}
