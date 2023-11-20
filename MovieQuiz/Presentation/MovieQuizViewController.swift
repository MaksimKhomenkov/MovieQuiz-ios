import UIKit

final class MovieQuizViewController: UIViewController, QuestionFactoryDelegate {
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask { .portrait }
    
    @IBOutlet private weak var yesButton: UIButton!
   
    @IBOutlet private weak var noButton: UIButton!
    
    @IBOutlet private weak var imageView: UIImageView!
    
    @IBOutlet private weak var textLabel: UILabel!
    
    @IBOutlet private weak var counterLabel: UILabel!
    

    private var currentQuestionIndex: Int = 0
    private var correctAnswers: Int = 0
    private let questionsAmount: Int = 10
    private var questionFactory: QuestionFactoryProtocol?
    private var currentQuestion: QuizQuestion?
    private var alertPresenter: AlertPresenter?
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        questionFactory = QuestionFactory()
        questionFactory?.delegate = self
        questionFactory?.requestNextQuestion()
        alertPresenter = AlertPresenter(viewController: self)
    }
    // MARK: - QuestionFactoryDelegate
    func didRecieveNextQuestion(question: QuizQuestion?) {
        guard let question = question else {
            return
        }
        currentQuestion = question
        let viewModel = convert(model: question)
        DispatchQueue.main.async { [weak self] in
            self?.show(quiz: viewModel)
        }
    }
    // MARK: - Private func
    private func convert(model: QuizQuestion) -> QuizStepViewModel {
        let questionStep = QuizStepViewModel(
            image: UIImage(named: model.image) ?? UIImage(),
            question: model.text,
            questionNumber: "\(currentQuestionIndex + 1)/\(questionsAmount)")
        return questionStep
    }
    
    private func show(quiz step: QuizStepViewModel){
        imageView.image = step.image
        textLabel.text = step.question
        counterLabel.text = step.questionNumber
    }
    
    private func showAnswerResult(isCorrect: Bool) {
        imageView.layer.masksToBounds = true
        imageView.layer.borderWidth = 8
        imageView.layer.borderColor = isCorrect ? UIColor.ypGreen.cgColor : UIColor.ypRed.cgColor
        if isCorrect {
            correctAnswers += 1
        }
        yesButton.isEnabled = false
        noButton.isEnabled = false
    
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0){ [weak self] in
            guard let self = self else { return }
            
            self.showNextQuestionOrResult()
            self.imageView.layer.borderColor = UIColor.clear.cgColor
            self.yesButton.isEnabled = true
            self.noButton.isEnabled = true
        }
    }
    private func showNextQuestionOrResult(){
        if currentQuestionIndex == questionsAmount - 1 {
            show()
        } else {
            currentQuestionIndex += 1
            
            self.questionFactory?.requestNextQuestion()
        }
    }
    private func show(){
        let alertModel = AlertModel(
            title: "Этот раунд окончен!",
            message: """
                Ваш результат: \(correctAnswers)/\(questionsAmount)
                Колличество сыграных квизов:
                Рекорд:
                Средняя точность:
                """,
            buttonText: "Сыграть еще раз",
            buttonAction: { [weak self] in
                self?.currentQuestionIndex = 0
                self?.correctAnswers = 0
                self?.questionFactory?.requestNextQuestion()
            })
        alertPresenter?.show(alertModel: alertModel)
    }
    
    @IBAction private func yesButtonTap(_ sender: Any) {
        guard let currentQuestion = currentQuestion else {
            return
        }
        let givenAnswer = true
        
        showAnswerResult(isCorrect: givenAnswer == currentQuestion.correctAnswer)
    }
    @IBAction private func noButtonTap(_ sender: Any) {
        guard let currentQuestion = currentQuestion else {
            return
        }
        let givenAnswer = false
        
        showAnswerResult(isCorrect: givenAnswer == currentQuestion.correctAnswer)
    }
}
