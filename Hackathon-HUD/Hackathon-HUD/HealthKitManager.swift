import HealthKit

class HealthKitManager {
    private let healthStore = HKHealthStore()
    static let shared = HealthKitManager()

    private enum HealthKitManagerError: Error {
        case notAvailableOnDevice
        case dataTypeNotAvailable
    }

    private init() {
        
    }

    func authorizeHealthKit(completion: @escaping (Bool, Error?) -> Swift.Void) {
        guard HKHealthStore.isHealthDataAvailable() else {
            completion(false, HealthKitManagerError.notAvailableOnDevice)
            return
        }

        guard let dateOfBirth = HKObjectType.characteristicType(forIdentifier: .dateOfBirth),
            let bloodType = HKObjectType.characteristicType(forIdentifier: .bloodType),
            let biologicalSex = HKObjectType.characteristicType(forIdentifier: .biologicalSex),
            let bodyMassIndex = HKObjectType.quantityType(forIdentifier: .bodyMassIndex),
            let height = HKObjectType.quantityType(forIdentifier: .height),
            let bodyMass = HKObjectType.quantityType(forIdentifier: .bodyMass),
            let activeEnergy = HKObjectType.quantityType(forIdentifier: .activeEnergyBurned),
            let heartRate = HKObjectType.quantityType(forIdentifier: .heartRate),
            let steps = HKObjectType.quantityType(forIdentifier: .stepCount)
            else {
                completion(false, HealthKitManagerError.dataTypeNotAvailable)
                return
        }

        let healthKitTypesToWrite: Set<HKSampleType> = [
            bodyMassIndex,
            activeEnergy,
            HKObjectType.workoutType()
        ]

        let healthKitTypesToRead: Set<HKObjectType> = [
            dateOfBirth,
            bloodType,
            biologicalSex,
            bodyMassIndex,
            height,
            bodyMass,
            heartRate,
            steps,
            HKObjectType.workoutType()
        ]

        healthStore.requestAuthorization(toShare: healthKitTypesToWrite, read: healthKitTypesToRead) { [weak self] (success, error) in
            guard let strongSelf = self else {
                return
            }
            if success {
                print("access to HEalthKit granted...")
                let readDataSet = Set<HKObjectType>(arrayLiteral: heartRate, steps)
                strongSelf.readHealthKitData()
                strongSelf.setUpBackgroundDeliveryForDataTypes(types: readDataSet)
            } else {
                debugPrint("Error requesting HealthKit authorization \(String(describing: error))")
            }
            DispatchQueue.main.async() {
                completion(success, error)
            }
        }
    }
}

private extension HealthKitManager {
    private func readHealthKitData() {

    }

    private func setUpBackgroundDeliveryForDataTypes(types: Set<HKObjectType>) {
        types.forEach { (type) in
            guard let type = type as? HKSampleType else {
                return
            }
            let query = HKObserverQuery(sampleType: type, predicate: nil, updateHandler: { [weak self ] (query, completionHandler, error) in
                debugPrint("observer query update handler called for type \(type), error: \(String(describing: error))")
                guard let strongSelf = self else {
                    return
                }
                strongSelf.queryForUpdates(type: type)
                completionHandler()
            })
            healthStore.execute(query)
            healthStore.enableBackgroundDelivery(for: type, frequency: .immediate, withCompletion: { (success, error) in
                print("enableBackgroundDeliveryForType handler called for \(type) - success: \(success), error: \(String(describing: error))")
            })
        }
    }

    private func queryForUpdates(type: HKObjectType) {
        switch type {
        case HKObjectType.quantityType(forIdentifier: .heartRate):
            print("heart rate")
        case HKObjectType.quantityType(forIdentifier: .height):
            print("height")
        case HKObjectType.quantityType(forIdentifier: .bodyMass):
            print("body mass")
        case HKObjectType.quantityType(forIdentifier: .activeEnergyBurned):
            print("active energy burned")
        case HKObjectType.quantityType(forIdentifier: .stepCount):
            print("step count")
        case HKObjectType.characteristicType(forIdentifier: .biologicalSex):
            print("biological sex")
        case HKObjectType.characteristicType(forIdentifier: .bloodType):
            print("blood type")
        case HKObjectType.characteristicType(forIdentifier: .dateOfBirth):
            print("date of birth")
        default:
            print("unknown type: \(type)")
        }
    }
}
