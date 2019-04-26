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

#include "experimentationrecordm.h"


/**
 * @brief Constructor
 * @param name
 * @param subject
 * @param task
 * @param startDateTime
 * @param parent
 */
ExperimentationRecordM::ExperimentationRecordM(QString uid,
                 QString name,
                 SubjectM* subject,
                 TaskM* task,
                 QDateTime startDateTime,
                 QObject *parent) : QObject(parent),
    _uid(uid),
    _name(name),
    _subject(subject),
    _task(task),
    _startDateTime(startDateTime),
    _endDateTime(QDateTime()),
    //_duration(QDateTime())
    _duration(QTime()),
    _mapIndependentVariableValues(nullptr)
{
    // Force ownership of our object, it will prevent Qml from stealing it
    QQmlEngine::setObjectOwnership(this, QQmlEngine::CppOwnership);

    if ((_subject != nullptr) && (_task != nullptr))
    {
        qInfo() << "New Model of Record" << _name << "(" << _uid << ") for subject" << _subject->name() << "and task" << _task->name() << "at" << _startDateTime.toString("dd/MM/yyyy hh:mm:ss");

        // Create the "Qml Property Map" that allows to set key-value pairs that can be used in QML bindings
        _mapIndependentVariableValues = new QQmlPropertyMap(this);

        for (IndependentVariableM* independentVariable : _task->independentVariables()->toList())
        {
            if (independentVariable != nullptr)
            {
                /*switch (independentVariable->valueType())
                {
                case IndependentVariableValueTypes::INTEGER:
                    _mapIndependentVariableValues->insert(independentVariable->name(), QVariant(0));
                    break;

                case IndependentVariableValueTypes::DOUBLE:
                    _mapIndependentVariableValues->insert(independentVariable->name(), QVariant(0.0));
                    break;

                case IndependentVariableValueTypes::TEXT:
                    _mapIndependentVariableValues->insert(independentVariable->name(), QVariant(""));
                    break;

                case IndependentVariableValueTypes::INDEPENDENT_VARIABLE_ENUM:
                    _mapIndependentVariableValues->insert(independentVariable->name(), QVariant(""));
                    break;

                default:
                    qWarning() << "We cannot add the independent variable" << independentVariable->name() << "because the type" <<  independentVariable->valueType() << "is wrong !";
                    break;
                }*/

                // Insert an (invalid) not initialized QVariant
                _mapIndependentVariableValues->insert(independentVariable->name(), QVariant());
            }
        }

        // FIXME TODO: connect to changes from the list _task->independentVariables()
        // Useless because "rootItem.record.mapIndependentVariableValues[model.name] = value" in QML/JS works...
        // ...even if the key was not inserted in C++ first (_mapIndependentVariableValues->insert(independentVariable->name(), QVariant()))
        //connect(_task->independentVariables(), &AbstractI2CustomItemListModel::countChanged, this, &ExperimentationRecordM::_onIndependentVariablesListChanged);


        // Connect to signal "Value Changed" fro the "Qml Property Map"
        //connect(_mapIndependentVariableValues, &QQmlPropertyMap::valueChanged, this, &ExperimentationRecordM::_onIndependentVariableValueChanged);
    }
}


/**
 * @brief Destructor
 */
ExperimentationRecordM::~ExperimentationRecordM()
{
    if ((_subject != nullptr) && (_task != nullptr))
    {
        qInfo() << "Delete Model of Record" << _name << "(" << _uid << ") for subject" << _subject->name() << "and task" << _task->name() << "at" << _startDateTime.toString("dd/MM/yyyy hh:mm:ss");

        setsubject(nullptr);
        settask(nullptr);

        // Free memory
        if (_mapIndependentVariableValues != nullptr)
        {
            /*// Clear each value
            for (QString key : _mapIndependentVariableValues->keys())
            {
                _mapIndependentVariableValues->clear(key);
            }*/

            QQmlPropertyMap* temp = _mapIndependentVariableValues;
            setmapIndependentVariableValues(nullptr);
            delete temp;
        }
    }
}


/**
 * @brief Setter for property "End Date Time"
 * @param value
 */
void ExperimentationRecordM::setendDateTime(QDateTime value)
{
    if (_endDateTime != value)
    {
        _endDateTime = value;

        // Update the duration
        qint64 milliSeconds = _startDateTime.msecsTo(_endDateTime);
        QTime time = QTime(0, 0, 0, 0).addMSecs(static_cast<int>(milliSeconds));

        //setduration(QDateTime(_startDateTime.date(), time));
        setduration(time);

        Q_EMIT endDateTimeChanged(value);
    }
}
