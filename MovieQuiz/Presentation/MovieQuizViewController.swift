import UIKit

protocol MovieQuizViewControllerProtocol: AnyObject {
    func show(quiz step: QuizStepViewModel)
    func show()
    func highlightImageBorder(isCorrectAnswer: Bool)
    func showLoadingIndicator()
    func hideLoadingIndicator()
    func showNetworkError(message: String)
}

final class MovieQuizViewController: UIViewController, MovieQuizViewControllerProtocol {
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask { .portrait }
    
    @IBOutlet private weak var yesButton: UIButton!
    @IBOutlet private weak var noButton: UIButton!
    @IBOutlet private weak var imageView: UIImageView!
    @IBOutlet private weak var textLabel: UILabel!
    @IBOutlet private weak var counterLabel: UILabel!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    private var presenter: MovieQuizPresenter!
    private var currentQuestion: QuizQuestion?
    private var alertPresenter: ResultAlertPresenter?
    private var statisticService: StatisticServiceProtocol?
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        presenter = MovieQuizPresenter(viewController: self)
        alertPresenter = ResultAlertPresenter(viewController: self)
        statisticService = StatisticService()
        showLoadingIndicator()
        presenter.questionFactory?.loadData()
    }
    
    // MARK: - func
    
    func show(quiz step: QuizStepViewModel) {
        imageView.image = step.image
        textLabel.text = step.question
        counterLabel.text = step.questionNumber
        
        yesButton.isEnabled = true
        noButton.isEnabled = true
    }
    
    func highlightImageBorder(isCorrectAnswer: Bool) {
        imageView.layer.masksToBounds = true
        imageView.layer.borderWidth = 8
        imageView.layer.borderColor = isCorrectAnswer ? UIColor.ypGreen.cgColor : UIColor.ypRed.cgColor
        
        yesButton.isEnabled = false
        noButton.isEnabled = false
    }
    
    func hideImageBorder() {
        imageView.layer.borderColor = UIColor.clear.cgColor
    }
    
    func show() {
        statisticService?.store(correct: presenter.correctAnswers, total: presenter.questionsAmount)
        
        guard let bestGame = statisticService?.bestGame,
              let statService = statisticService else {
            print("Statistic Error!")
            return
        }
        
        let alertModel = AlertModel(
            title: "Этот раунд окончен!",
            message: """
                    Ваш результат: \(presenter.correctAnswers)/\(presenter.questionsAmount)
                    Колличество сыгранных квизов: \(statService.gamesCount)
                    Рекорд: \(bestGame.correct)/\(bestGame.total) (\(bestGame.date.dateTimeString))
                    Средняя точность: \(String(format: "%.2f", statService.totalAccuracy))%
                    """,
            buttonText: "Сыграть еще раз",
            buttonAction: { [weak self] in
                self?.presenter.restartGame()
            })
        alertPresenter?.show(alertModel: alertModel)
    }
    
    func showLoadingIndicator() {
        activityIndicator.isHidden = false
        activityIndicator.startAnimating()
    }
    
    func hideLoadingIndicator() {
        activityIndicator.isHidden = true
    }
    
    func showNetworkError(message: String) {
        activityIndicator.isHidden = true
        
        let model = AlertModel(title: "Ошибка",
                               message: message,
                               buttonText: "Попробовать еще раз") { [weak self] in
            guard let self = self else { return }
            
            self.presenter.restartGame()
            self.showLoadingIndicator()
            self.presenter.questionFactory?.loadData()
        }
        alertPresenter?.show(alertModel: model)
    }
    
    // MARK: - IBActions
    @IBAction private func yesButtonTap(_ sender: Any) {
        presenter.yesButtonTap()
    }
    @IBAction private func noButtonTap(_ sender: Any) {
        presenter.noButtonTap()
    }
}
