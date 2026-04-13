part of 'survey.dart';

/// A task representing the [WHO-5 well-being index](https://www.psykiatri-regionh.dk/who-5/Pages/default.aspx).
/// Included as an example.
RPOrderedTask who5Task = RPOrderedTask(
  identifier: "who5_task",
  steps: [
    _who5Question1,
    _who5Question2,
    _who5Question3,
    _who5Question4,
    _who5Question5,
    _completionStep,
  ],
);

List<RPChoice> _who5Choices = [
  RPChoice(text: "All of the time", value: 5),
  RPChoice(text: "Most of the time", value: 4),
  RPChoice(text: "More than half of the time", value: 3),
  RPChoice(text: "Less than half of the time", value: 2),
  RPChoice(text: "Some of the time", value: 1),
  RPChoice(text: "At no time", value: 0),
];

RPChoiceAnswerFormat _choiceAnswerFormat = RPChoiceAnswerFormat(
  answerStyle: RPChoiceAnswerStyle.SingleChoice,
  choices: _who5Choices,
);

RPQuestionStep _who5Question1 = RPQuestionStep(
  identifier: "who5_question_1",
  title: "I have felt cheerful and in good spirits",
  answerFormat: _choiceAnswerFormat,
);

RPQuestionStep _who5Question2 = RPQuestionStep(
  identifier: "who5_question_2",
  title: "I have felt calm and relaxed",
  answerFormat: _choiceAnswerFormat,
);

RPQuestionStep _who5Question3 = RPQuestionStep(
  identifier: "who5_question_3",
  title: "I have felt active and vigorous",
  answerFormat: _choiceAnswerFormat,
);

RPQuestionStep _who5Question4 = RPQuestionStep(
  identifier: "who5_question_4",
  title: "I woke up feeling fresh and rested",
  answerFormat: _choiceAnswerFormat,
);

RPQuestionStep _who5Question5 = RPQuestionStep(
  identifier: "who5_question_5",
  title: "My daily life has been filled with things that interest me",
  answerFormat: _choiceAnswerFormat,
);

RPCompletionStep _completionStep = RPCompletionStep(
  identifier: "completion_step",
  title: "Finished",
  text: "Thank you for filling out the survey!",
);
