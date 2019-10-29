/*
 *	IngeScape Common
 *
 *  Copyright © 2017-2019 Ingenuity i/o. All rights reserved.
 *
 *	See license terms for the rights and conditions
 *	defined by copyright holders.
 *
 *
 *	Contributors:
 *      Vincent Peyruqueou  <peyruqueou@ingenuity.io>
 *      Alexandre Lemort    <lemort@ingenuity.io>
 *
 */

#ifndef INGESCAPE_NETWORKCONTROLLER_H
#define INGESCAPE_NETWORKCONTROLLER_H

#include <QObject>
#include <QtQml>
#include <QQmlEngine>
#include <QJSEngine>

#include "I2PropertyHelpers.h"
#include <model/enums.h>


extern "C" {
#include <ingescape.h>
#include <ingescape_advanced.h>
#include <ingescape_private.h>
#include <czmq.h>
}


static const QString prefix_Definition = "EXTERNAL_DEFINITION#";
static const QString prefix_Mapping = "EXTERNAL_MAPPING#";


/**
 * @brief The IngeScapeNetworkController class defines the controller for IngeScape network communications
 */
class IngeScapeNetworkController: public QObject
{
    Q_OBJECT

    // List of available network devices
    I2_QML_PROPERTY_READONLY(QStringList, availableNetworkDevices)

    // Flag indicating if our agent is started
    I2_QML_PROPERTY_READONLY(bool, isStarted)

    // Flag indicating if our agent is online
    // NB: false when our agent is not started OR when its network device is no more available
    I2_QML_PROPERTY_READONLY(bool, isOnline)

    // Flag indicating if we must start/stop our agent automatically when we receive monitor events
    // NB: this flags exists to allow each application based on IngeScape-Common to define its own behavior
    //     By default, this property is set to false
    I2_QML_PROPERTY(bool, automaticallyStartStopOnMonitorEvents)

    // Number of each type of IngeScape applications
    I2_QML_PROPERTY_READONLY(int, numberOfAgents)
    I2_QML_PROPERTY_READONLY(int, numberOfLaunchers)
    I2_QML_PROPERTY_READONLY(int, numberOfRecorders)
    I2_QML_PROPERTY_READONLY(int, numberOfEditors)
    I2_QML_PROPERTY_READONLY(int, numberOfAssessments)
    I2_QML_PROPERTY_READONLY(int, numberOfExpes)


public:

    /**
     * @brief Constructor
     * @param igsServiceDescription
     * @param parent
     */
    explicit IngeScapeNetworkController(QObject *parent = nullptr);


    /**
      * @brief Destructor
      */
    ~IngeScapeNetworkController();


    /**
     * @brief Start our IngeScape agent with a network device (or an IP address) and a port
     * @param networkDevice
     * @param ipAddress
     * @param port
     * @return
     */
    bool start(QString networkDevice, QString ipAddress, uint port);


    /**
     * @brief Stop our IngeScape agent
     */
    void stop();


    /**
     * @brief Restart our ingescape agent (stop + start with arguments used in the last call to start)
     *
     * @return true if our agent has restarted
     */
    bool restart();


    /**
     * @brief start with previous configuration
     * @return
     */
    bool startWithPreviousConfiguration();



    /**
     * @brief Start monitoring
     *
     * @param expectedNetworkDevice
     * @param expectedPort
     */
    void startMonitoring(QString expectedNetworkDevice = "", uint expectedPort = 31520);


    /**
     * @brief Stop monitoring
     */
    void stopMonitoring();


    /**
     * @brief Get the IngeScape type of a peer id
     * @param peerId
     * @return
     */
    IngeScapeTypes::Value getIngeScapeTypeOfPeerId(QString peerId);


    /**
     * @brief Manage a peer id which entered the network
     * @param peerId
     * @param ingeScapeType
     */
    void manageEnteredPeerId(QString peerId, IngeScapeTypes::Value ingeScapeType);


    /**
     * @brief Manage a peer id which exited the network
     * @param peerId
     */
    void manageExitedPeerId(QString peerId);


    /**
     * @brief Update the list of available network devices
     */
    Q_INVOKABLE void updateAvailableNetworkDevices();


    /**
     * @brief Return true if the network device is available
     * @param networkDevice
     * @return
     */
    Q_INVOKABLE bool isAvailableNetworkDevice(QString networkDevice);


    /**
     * @brief Manage a "Shouted" message
     * @param peerId
     * @param peerName
     * @param zMessage
     */
    virtual void manageShoutedMessage(QString peerId, QString peerName, zmsg_t* zMessage);


    /**
     * @brief Manage a "Whispered" message
     * @param peerId
     * @param peerName
     * @param zMessage
     */
    virtual void manageWhisperedMessage(QString peerId, QString peerName, zmsg_t* zMessage);


Q_SIGNALS:
    /**
     * @brief Triggered when our network device is not available
     */
    void networkDeviceIsNotAvailable();


    /**
     * @brief Triggered when our network device is available again
     */
    void networkDeviceIsAvailableAgain();


    /**
     * @brief Triggered when our network device has a new IP address
     * @param newIpAddress
     */
    void networkDeviceIpAddressHasChanged(QString newIpAddress);


    /**
     * @brief Signal emitted when an "IngeScape Agent" enter the network
     * @param peerId
     * @param peerName
     * @param ipAddress
     * @param hostname
     * @param commandLine
     * @param canBeFrozen
     * @param loggerPort
     */
    void agentEntered(QString peerId, QString peerName, QString ipAddress, QString hostname, QString commandLine, bool canBeFrozen, QString loggerPort);


    /**
     * @brief Signal emitted when an "IngeScape Agent" quit the network
     * @param peer id
     * @param peer name
     */
    void agentExited(QString peerId, QString peerName);


    /**
     * @brief Signal emitted when an "IngeScape Launcher" enter the network
     * @param peerId
     * @param hostname
     * @param ipAddress
     */
    void launcherEntered(QString peerId, QString hostname, QString ipAddress, QString streamingPort);


    /**
     * @brief Signal emitted when an "IngeScape Launcher" quit the network
     * @param peerId
     * @param hostname
     */
    void launcherExited(QString peerId, QString hostname);


    /**
     * @brief Signal emitted when an "IngeScape Editor" enter the network
     * @param peerId
     * @param peerName
     * @param ipAddress
     * @param hostname
     */
    void editorEntered(QString peerId, QString peerName, QString ipAddress, QString hostname);


    /**
     * @brief Signal emitted when an "IngeScape Editor" quit the network
     * @param peerId
     * @param peerName
     */
    void editorExited(QString peerId, QString peerName);


    /**
     * @brief Signal emitted when an "IngeScape Recorder" enter the network
     * @param peerId
     * @param peerName
     * @param ipAddress
     * @param hostname
     */
    void recorderEntered(QString peerId, QString peerName, QString ipAddress, QString hostname);


    /**
     * @brief Signal emitted when an "IngeScape Recorder" quit the network
     * @param peerId
     * @param peerName
     */
    void recorderExited(QString peerId, QString peerName);


    /**
     * @brief Signal emitted when an "IngeScape Expe" enter the network
     * @param peerId
     * @param peerName
     * @param ipAddress
     * @param hostname
     */
    void expeEntered(QString peerId, QString peerName, QString ipAddress, QString hostname);


    /**
     * @brief Signal emitted when an "IngeScape Expe" quit the network
     * @param peerId
     * @param peerName
     */
    void expeExited(QString peerId, QString peerName);


    /**
     * @brief Signal emitted when an "IngeScape Assessments" enter the network
     * @param peerId
     * @param peerName
     * @param ipAddress
     * @param hostname
     */
    void assessmentsEntered(QString peerId, QString peerName, QString ipAddress, QString hostname);


    /**
     * @brief Signal emitted when an "IngeScape Assessments" quit the network
     * @param peerId
     * @param peerName
     */
    void assessmentsExited(QString peerId, QString peerName);


    /**
     * @brief Signal emitted when an agent definition has been received
     * @param peer id
     * @param peer name
     * @param definitionJSON
     */
    void definitionReceived(QString peerId, QString peerName, QString definitionJSON);


    /**
     * @brief Signal emitted when an agent mapping has been received
     * @param peerId
     * @param peerName
     * @param mappingJSON
     */
    void mappingReceived(QString peerId, QString peerName, QString mappingJSON);


public Q_SLOTS:

    /**
     * @brief Slot called when a command must be sent on the network to a recorder
     * @param peerIdOfRecorder
     * @param commandAndParameters
     */
    void onCommandAskedToRecorder(QString peerIdOfRecorder, QString commandAndParameters);


protected:
    // Name of our "IngeScape" agent that correspond to our application
    QString _igsAgentApplicationName;

    // Hash table from a peer id to a type of IngeScape elements on the network
    QHash<QString, IngeScapeTypes::Value> _hashFromPeerIdToIngeScapeType;

    // Last agruments of start
    QString _lastArgumentsOfStart_networkDevice;
    QString _lastArgumentsOfStart_ipAddress;
    uint _lastArgumentsOfStart_port;
};

QML_DECLARE_TYPE(IngeScapeNetworkController)

#endif // INGESCAPE_NETWORKCONTROLLER_H
