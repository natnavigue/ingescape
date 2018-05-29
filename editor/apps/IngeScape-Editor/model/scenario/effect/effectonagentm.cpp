/*
 *	IngeScape Editor
 *
 *  Copyright Â© 2017 Ingenuity i/o. All rights reserved.
 *
 *	See license terms for the rights and conditions
 *	defined by copyright holders.
 *
 *
 *	Contributors:
 *      Vincent Peyruqueou <peyruqueou@ingenuity.io>
 *
 */

#include "effectonagentm.h"

/**
 * @brief Enum "AgentEffectValues" to string
 * @param value
 * @return
 */
QString AgentEffectValues::enumToString(int value)
{
    switch (value)
    {
    case AgentEffectValues::ON:
        return tr("ON");

    case AgentEffectValues::OFF:
        return tr("OFF");

    case AgentEffectValues::MUTE:
        return tr("MUTE");

    case AgentEffectValues::UNMUTE:
        return tr("UNMUTE");

    case AgentEffectValues::FREEZE:
        return tr("FREEZE");

    case AgentEffectValues::UNFREEZE:
        return tr("UNFREEZE");

    default:
        return "";
    }
}


//--------------------------------------------------------------
//
// EffectOnAgentM
//
//--------------------------------------------------------------

/**
 * @brief Constructor
 * @param parent
 */
EffectOnAgentM::EffectOnAgentM(QObject *parent) : ActionEffectM(parent),
    _agentEffectValue(AgentEffectValues::ON)
{
    // Force ownership of our object, it will prevent Qml from stealing it
    QQmlEngine::setObjectOwnership(this, QQmlEngine::CppOwnership);

}


/**
  * @brief Destructor
  */
EffectOnAgentM::~EffectOnAgentM()
{

}


/**
* @brief Copy from another effect model
* @param effect to copy
*/
void EffectOnAgentM::copyFrom(ActionEffectM* effect)
{
    // Call mother class
    ActionEffectM::copyFrom(effect);

    EffectOnAgentM* effectOnAgent = qobject_cast<EffectOnAgentM*>(effect);
    if (effectOnAgent != NULL)
    {
        setagentEffectValue(effectOnAgent->agentEffectValue());
    }
}


/**
 * @brief Get a pair with the agent and the command (with parameters) of our effect
 * @return
 */
QPair<AgentInMappingVM*, QStringList> EffectOnAgentM::getAgentAndCommandWithParameters()
{
    QPair<AgentInMappingVM*, QStringList> pairAgentAndCommandWithParameters;

    if (_agent != NULL)
    {
        pairAgentAndCommandWithParameters.first = _agent;

        QStringList commandAndParameters;

        switch (_agentEffectValue)
        {
        case AgentEffectValues::ON: {
            commandAndParameters << "RUN";
            break;
        }
        case AgentEffectValues::OFF: {
            commandAndParameters << "STOP";
            break;
        }
        default:
            break;
        }

        pairAgentAndCommandWithParameters.second = commandAndParameters;
    }

    return pairAgentAndCommandWithParameters;
}


/**
 * @brief Get a pair with the agent name and the reverse command (with parameters) of our effect
 * @return
 */
QPair<QString, QStringList> EffectOnAgentM::getAgentNameAndReverseCommandWithParameters()
{
    QPair<QString, QStringList> pairAgentNameAndReverseCommand;

    if (_agent != NULL)
    {
        pairAgentNameAndReverseCommand.first = _agent->name();

        QStringList reverseCommandAndParameters;

        switch (_agentEffectValue)
        {
        case AgentEffectValues::ON: {
            reverseCommandAndParameters << "STOP";
            break;
        }
        case AgentEffectValues::OFF: {
            reverseCommandAndParameters << "RUN";
            break;
        }
        default:
            break;
        }

        pairAgentNameAndReverseCommand.second = reverseCommandAndParameters;
    }

    return pairAgentNameAndReverseCommand;
}
