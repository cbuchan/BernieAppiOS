import UIKit

class OnboardingWorkflow {
    private let applicationSettingsRepository: ApplicationSettingsRepository
    private let onboardingController: UIViewController
    private let postOnboardingController: UIViewController
    private let pushNotificationRegistrar: PushNotificationRegistrar
    private let application: ApplicationUserNotificationHandler

    init(
        applicationSettingsRepository: ApplicationSettingsRepository,
        onboardingController: UIViewController,
        postOnboardingController: UIViewController,
        pushNotificationRegistrar: PushNotificationRegistrar,
        application: ApplicationUserNotificationHandler) {
            self.applicationSettingsRepository = applicationSettingsRepository
            self.onboardingController = onboardingController
            self.postOnboardingController = postOnboardingController
            self.pushNotificationRegistrar = pushNotificationRegistrar
            self.application = application
    }

    func initialViewController(completion: (UIViewController) -> Void) {
        applicationSettingsRepository.termsAndConditionsAgreed { (termsHaveBeenAgreed) -> Void in
            completion(termsHaveBeenAgreed ? self.postOnboardingController : self.onboardingController)
        }
    }

    func controllerDidFinishOnboarding(controller: UIViewController) {
        self.pushNotificationRegistrar.registerForRemoteNotificationsWithApplication(self.application)
        controller.presentViewController(self.postOnboardingController, animated: true, completion: nil)
    }
}
