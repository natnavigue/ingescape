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

#include "assessmentsenums.h"

/**
 * @brief Enum to string
 * @param value
 * @return
 */
QString CharacteristicValueTypes::enumToString(int value)
{
    switch (value)
    {
    case CharacteristicValueTypes::UNKNOWN:
        return tr("Unknown");

    case CharacteristicValueTypes::INTEGER:
        //return tr("Integer");
        return tr("Integer number");

    case CharacteristicValueTypes::DOUBLE:
        //return tr("Double");
        return tr("Floating number");

    case CharacteristicValueTypes::TEXT:
        return tr("Text");

    case CharacteristicValueTypes::CHARACTERISTIC_ENUM:
        return tr("Enum");
        //return tr("Enumeration");

    default:
        return "";
    }
}


/**
 * @brief Enum to string
 * @param value
 * @return
 */
QString IndependentVariableValueTypes::enumToString(int value)
{
    switch (value)
    {
    case IndependentVariableValueTypes::UNKNOWN:
        return tr("Unknown");

    case IndependentVariableValueTypes::INTEGER:
        //return tr("Integer");
        return tr("Integer number");

    case IndependentVariableValueTypes::DOUBLE:
        //return tr("Double");
        return tr("Floating number");

    case CharacteristicValueTypes::TEXT:
        return tr("Text");

    case IndependentVariableValueTypes::INDEPENDENT_VARIABLE_ENUM:
        return tr("Enum");
        //return tr("Enumeration");

    default:
        return "";
    }
}


/**
 * @brief Enum to string
 * @param value
 * @return
 */
QString ValueTypes::enumToString(int value)
{
    switch (value)
    {
    case ValueTypes::UNKNOWN:
        return tr("Unknown");

    case ValueTypes::INTEGER:
        return tr("Integer number");

    case ValueTypes::DOUBLE:
        return tr("Floating number");

    case ValueTypes::TEXT:
        return tr("Text");

    case ValueTypes::ENUM:
        return tr("Enumeration");

    default:
        return "";
    }
}


//--------------------------------------------------------------
//
//  Assessments Enums
//
//--------------------------------------------------------------

/**
 * @brief Constructor
 * @param parent
 */
AssessmentsEnums::AssessmentsEnums(QObject *parent) : QObject(parent)
{
    // Force ownership of our object, it will prevent Qml from stealing it
    QQmlEngine::setObjectOwnership(this, QQmlEngine::CppOwnership);
}
