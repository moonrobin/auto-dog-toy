//
//  ViewController.swift
//  SimpleBleCentral
//
//  Created by Group 42 on 12/03/2019.
//

import UIKit
import BlueCapKit
import CoreBluetooth

class ViewController: UIViewController, UITextViewDelegate {
    
    public enum AppError : Error {
        case dataCharactertisticNotFound
        case enabledCharactertisticNotFound
        case updateCharactertisticNotFound
        case serviceNotFound
        case invalidState
        case resetting
        case poweredOff
        case unknown
    }

    @IBOutlet weak var statusLabel: UILabel!

    @IBOutlet weak var segmentedControl: UISegmentedControl!

    @IBOutlet weak var mybutton: UIButton!
    
    @IBOutlet weak var readButton: UIButton!
    
    @IBOutlet weak var sessionPlayTimeLabel: UILabel!
    
    @IBOutlet weak var totalPlayTimeLabel: UILabel!

    @IBOutlet weak var sessionDistanceLabel: UILabel!
    
    @IBOutlet weak var totalDistanceLabel: UILabel!
    
    @IBOutlet weak var spinwheel: UIActivityIndicatorView!

    @IBOutlet weak var dogPicture: UIImageView!

    @IBOutlet weak var coolDogePicture: UIImageView!
    
    @IBAction func onModeChange(_ sender: UISegmentedControl) {
        switch segmentedControl.selectedSegmentIndex {
        case 0:
            write(0)
        case 1:
            write(1)
        case 2:
            write(2)
        default:
            break
        }
    }

    var dataCharacteristic : Characteristic?

    // update play time every minute
    var sessionPlayTime = 0;
    var totalPlayTime = 0;
    var timer: Timer!

    @objc func updatePlayTime() {
        sessionPlayTime += 1
        totalPlayTime += 1
        self.updatePlayTimeLabels()
        self.writeTotalPlayTime()
    }

    func updatePlayTimeLabels() {
        if (totalPlayTime > 60) {
            self.totalPlayTimeLabel.text = String(format: "%.2f",Double(totalPlayTime)/60.0) + " h"
        } else {
            self.totalPlayTimeLabel.text = String(totalPlayTime) + " min"
        }
        self.sessionPlayTimeLabel.text = String(sessionPlayTime) + " min"
    }

    func readTotalPlayTime() {
        let defaults = UserDefaults.standard
        totalPlayTime = defaults.integer(forKey: "totalPlayTime")
    }

    func writeTotalPlayTime() {
        let defaults = UserDefaults.standard
        defaults.set(totalPlayTime, forKey: "totalPlayTime")
    }

    var isConnected = false;
    @objc func checkConnection() {
        if (self.manager.isDisconnected == true){
            if (isConnected) {
                print("disconnected")
                self.deviceDisconnected()
            }
        } else if (!isConnected){
            print("connected")
            self.deviceConnected()
        }
    }

    func deviceConnected() {
        self.isConnected = true;
        self.statusLabel.text = "Connected to Rover."
        self.spinwheel.stopAnimating()
        self.dogPicture.isHidden = false
        // start counting play time
        self.timer = Timer.scheduledTimer(timeInterval: 60, target: self, selector: #selector(self.updatePlayTime), userInfo: nil, repeats: true)
        self.startCountingDistance()
    }

    func deviceDisconnected() {
        self.isConnected = false;
        self.statusLabel.text = "Searching for Rover..."
        self.spinwheel.startAnimating()
        self.dogPicture.isHidden = true
        // stop counting play time
        if (self.timer != nil) {
            self.timer!.invalidate()
            self.timer = nil
        }
        self.stopCountingDistance()
        connect()
    }
    

    
    // fake data for demo purposes only
    let averageSpeedPerSec = 0.7
    var distanceTimer: Timer!
    var sessionDistanceTravelled = 0.0
    var totalDistanceTravelled = 0.0
    @IBOutlet weak var invisButton: UIButton!
    // every 3 seconds
    @objc func updateDistanceTravelled() {
        let distanceTravelled = (0.5+drand48())*averageSpeedPerSec
        sessionDistanceTravelled += distanceTravelled
        totalDistanceTravelled += distanceTravelled
        self.updateDistanceTravelledLabels()
        self.writeTotalDistanceTravelled()
    }
    
    func updateDistanceTravelledLabels() {
        self.totalDistanceLabel.text = String(format: "%.2f",totalDistanceTravelled/1000) + " km"
        self.sessionDistanceLabel.text = String(format: "%.2f",sessionDistanceTravelled) + " m"
    }
    
    func readTotalDistanceTravelled() {
        let defaults = UserDefaults.standard
        totalDistanceTravelled = defaults.double(forKey: "totalDistanceTravelled")
    }
    
    func writeTotalDistanceTravelled() {
        let defaults = UserDefaults.standard
        defaults.set(totalDistanceTravelled, forKey: "totalDistanceTravelled")
    }
    func startCountingDistance() {
        self.distanceTimer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(self.updateDistanceTravelled), userInfo: nil, repeats: true)
    }
    func stopCountingDistance() {
        if (self.distanceTimer != nil) {
            self.distanceTimer!.invalidate()
            self.distanceTimer = nil
        }
    }

    func initializeLabels() {
        self.readTotalPlayTime()
        self.readTotalDistanceTravelled()
        self.updatePlayTimeLabels()
        self.updateDistanceTravelledLabels()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.timer = Timer.scheduledTimer(timeInterval: 2, target: self, selector: #selector(self.checkConnection), userInfo: nil, repeats: true)
        self.initializeLabels()
        self.deviceDisconnected()
    }

    //the restore key allows to resuse the same central manager in future calls
    let manager = CentralManager(options: [CBCentralManagerOptionRestoreIdentifierKey : "CentralMangerKey" as NSString])
    func connect(){
        let serviceUUID = CBUUID(string: "FFE0")
        let characteristicUUID = CBUUID(string: "FFE1")
        var peripheral: Peripheral?

        let stateChangeFuture = manager.whenStateChanges()

        //handle state changes and return a scan future if the bluetooth is powered on
        let scanFuture = stateChangeFuture.flatMap { state -> FutureStream<Peripheral> in
            switch state {
            case .poweredOn:
                DispatchQueue.main.async {
                    print("start scanning")
                }
                //scan for peripherlas that advertise the ec00 service
                return self.manager.startScanning(forServiceUUIDs: [serviceUUID])
            case .poweredOff:
                print("powered off")
                throw AppError.poweredOff
            case .unauthorized, .unsupported:
                print("unauthorized")
                throw AppError.invalidState
            case .resetting:
                print("resetting")
                throw AppError.resetting
            case .unknown:
                print("unknown")
                //generally this state is ignored
                throw AppError.unknown
            }
        }
    
        scanFuture.onFailure { error in
            guard let appError = error as? AppError else {
                return
            }
            switch appError {
            case .invalidState:
                break
            case .resetting:
                self.manager.reset()
            case .poweredOff:
                break
            case .unknown:
                break
            default:
                break;
            }
        }

        //connect to the first scanned peripheral
        let connectionFuture = scanFuture.flatMap { p -> FutureStream<Void> in
            //stop the scan as soon as we find the first peripheral
            self.manager.stopScanning()
            peripheral = p
            guard let peripheral = peripheral else {
                throw AppError.unknown
            }
            DispatchQueue.main.async {
                print("Found peripheral \(peripheral.identifier.uuidString). Trying to connect")
            }
            //connect to the peripheral in order to trigger the connected mode
            return peripheral.connect(connectionTimeout: 10, capacity: 5)
        }
    
        //discover service in order be able to access its characteristics
        let discoveryFuture = connectionFuture.flatMap { _ -> Future<Void> in
            guard let peripheral = peripheral else {
                throw AppError.unknown
            }
            return peripheral.discoverServices([serviceUUID])
            }.flatMap { _ -> Future<Void> in
                guard let discoveredPeripheral = peripheral else {
                    throw AppError.unknown
                }
                guard let service = discoveredPeripheral.services(withUUID:serviceUUID)?.first else {
                    throw AppError.serviceNotFound
                }
                peripheral = discoveredPeripheral
                DispatchQueue.main.async {
                    print("Discovered service \(service.uuid.uuidString). Trying to discover characteristics")
                }
                //we have discovered Rover's BT module, the next step is to discover its characteristic
                return service.discoverCharacteristics([characteristicUUID])
        }
    
        /**
         1- checks if the characteristic is correctly discovered
         2- Register for notifications using the dataFuture variable
         */
        let dataFuture = discoveryFuture.flatMap { _ -> Future<Void> in
            guard let discoveredPeripheral = peripheral else {
                throw AppError.unknown
            }
            guard let dataCharacteristic = discoveredPeripheral.services(withUUID:serviceUUID)?.first?.characteristics(withUUID:characteristicUUID)?.first else {
                throw AppError.dataCharactertisticNotFound
            }
            self.dataCharacteristic = dataCharacteristic
            DispatchQueue.main.async {
                self.deviceConnected()
                print("Discovered characteristic \(dataCharacteristic.uuid.uuidString).")
            }

            //read the data from the characteristic
            self.read()
            //Ask the characteristic to start notifying for value change
            return dataCharacteristic.startNotifying()
            }.flatMap { _ -> FutureStream<Data?> in
                guard let discoveredPeripheral = peripheral else {
                    throw AppError.unknown
                }
                guard let characteristic = discoveredPeripheral.services(withUUID:serviceUUID)?.first?.characteristics(withUUID:characteristicUUID)?.first else {
                    throw AppError.dataCharactertisticNotFound
                }
                //regeister to recieve a notifcation when the value of the characteristic changes and return a future that handles these notifications
                return characteristic.receiveNotificationUpdates(capacity: 10)
        }
    
        //The onSuccess method is called every time the characteristic value changes
        dataFuture.onSuccess { data in
            let s = String(data:data!, encoding: .utf8)
            DispatchQueue.main.async {
                print("notified value is \(String(describing: s))")
            }
        }
    
        //handle any failure in the previous chain
        dataFuture.onFailure { error in
            switch error {
            case PeripheralError.disconnected:
                peripheral?.reconnect()
            case AppError.serviceNotFound:
                break
            case AppError.dataCharactertisticNotFound:
                break
            default:
                break
            }
        }
        
    }
    
    @IBAction func invisButtonTouch(_ sender: Any) {
        if (distanceTimer != nil) {
            //print("stop counting")
            self.stopCountingDistance()
        } else {
            //print("start counting")
            self.startCountingDistance()
        }
    }

    @IBAction func mybuttontouch(_ sender: UIButton) {
        if (sender == mybutton) {
            write(1)
        } else if (sender == readButton) {
            read()
        }
    }
    
    func read(){
        //read a value from the characteristic
        let readFuture = self.dataCharacteristic?.read(timeout: 5)
        readFuture?.onSuccess { (_) in
            //the value is in the dataValue property
            let s = String(data:(self.dataCharacteristic?.dataValue)!, encoding: .utf8)
            DispatchQueue.main.async {
                print("Read value is \(String(describing: s))")
            }
        }
        readFuture?.onFailure { (_) in
            DispatchQueue.main.async {
                print("read error")
            }
        }
    }
    
    func write(_ mode: integer_t){
        let text = String(mode)
        let writeType: CBCharacteristicWriteType = .withoutResponse
        let writeFuture = self.dataCharacteristic?.write(data: text.data(using: .utf8)!, type: writeType)
        writeFuture?.onSuccess(completion: { (_) in
            print("wrote value " + text + " successfully")
        })
        writeFuture?.onFailure(completion: { (e) in
            print("write failed")
            print(e.localizedDescription)
        })
    }
}
