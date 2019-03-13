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

    @IBOutlet weak var thatlabel: UILabel!
    var dataCharacteristic : Characteristic?

    @IBOutlet weak var segmentedControl: UISegmentedControl!
    
    @IBOutlet weak var mybutton: UIButton!
    
    
    @IBOutlet weak var readButton: UIButton!

    @IBAction func onModeChange(_ sender: UISegmentedControl) {
        switch segmentedControl.selectedSegmentIndex {
        case 0:
            thatlabel.text = "avoid"
            write(0)
        case 1:
            thatlabel.text = "chase"
            write(1)
        default:
            break
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        let serviceUUID = CBUUID(string: "FFE0")
        let characteristicUUID = CBUUID(string: "FFE1")
        var peripheral: Peripheral?

        //initialize a central manager with a restore key. The restore key allows to resuse the same central manager in future calls
        let manager = CentralManager(options: [CBCentralManagerOptionRestoreIdentifierKey : "CentralMangerKey" as NSString])

        //A future stram that notifies us when the state of the central manager changes
        let stateChangeFuture = manager.whenStateChanges()

        //handle state changes and return a scan future if the bluetooth is powered on.
        let scanFuture = stateChangeFuture.flatMap { state -> FutureStream<Peripheral> in
            switch state {
            case .poweredOn:
                DispatchQueue.main.async {
                    print("start scanning")
                }
                //scan for peripherlas that advertise the ec00 service
                return manager.startScanning(forServiceUUIDs: [serviceUUID])
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
            print("scan failure")
            switch appError {
            case .invalidState:
                break
            case .resetting:
                manager.reset()
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
            manager.stopScanning()
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
    
        print("finished connection")
    
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
                    self.thatlabel.text = "Discovered service \(service.uuid.uuidString). Trying to discover characteristics"
                    print(self.thatlabel.text!)
                }
                //we have discovered the service, the next step is to discover the "ec0e" characteristic
                return service.discoverCharacteristics([characteristicUUID])
        }
    
        print("finished discovery")
    
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
                self.thatlabel.text = "Discovered characteristic \(dataCharacteristic.uuid.uuidString)."
            }
            //            DispatchQueue.main.async {
            // TODO: add some UI that indicates connection
            //            }
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
                self.thatlabel.text = "notified value is \(String(describing: s))"
                print(String(describing: s))
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

    @IBAction func mybuttontouch(_ sender: UIButton) {
        if (sender == mybutton) {
            write(1)
        } else {
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
                self.thatlabel.text = "Read value is \(String(describing: s))"
                print(self.thatlabel.text!)
            }
        }
        readFuture?.onFailure { (_) in
            self.thatlabel.text = "read error"
        }
    }
    
    func write(_ mode: integer_t){
        var text:String;
        if (mode == 0) {
            text = "mode_avoid\r\n"
        } else {
            text = "mode_chase\r\n";
        }
        let writeType: CBCharacteristicWriteType = .withoutResponse
        let writeFuture = self.dataCharacteristic?.write(data: text.data(using: .utf8)!, type: writeType)
        writeFuture?.onSuccess(completion: { (_) in
            print("wrote value " + text + "successfully")
        })
        writeFuture?.onFailure(completion: { (e) in
            print("write failed")
            print(e.localizedDescription)
        })
    }



}
