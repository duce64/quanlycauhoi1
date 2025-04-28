import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutterquiz/blocs/auth/auth_bloc.dart';
import 'package:flutterquiz/login/login_screen.dart';
import 'package:flutterquiz/login/register_screen.dart';
import 'package:flutterquiz/model/categories.dart';
import 'package:flutterquiz/model/question.dart';
import 'package:flutterquiz/screen/ExamResultScreenUser.dart';
import 'package:flutterquiz/screen/QuestionPackageListScreenH.dart';
import 'package:flutterquiz/screen/admin/AddQuestionPackageScreen.dart';
import 'package:flutterquiz/screen/admin/CreateExamScreen.dart';
import 'package:flutterquiz/screen/admin/CreatedTestListScreen.dart';
import 'package:flutterquiz/screen/admin/ExamResultScreen.dart';
import 'package:flutterquiz/screen/admin/addQuestionScreen.dart';
import 'package:flutterquiz/screen/admin/admin_screen.dart';
import 'package:flutterquiz/screen/admin/category_admin_screen.dart';
import 'package:flutterquiz/screen/admin/edit_category_screen.dart';
import 'package:flutterquiz/screen/admin/manage_question_screen.dart';
import 'package:flutterquiz/screen/admin/mangage_user_screen.dart';
import 'package:flutterquiz/screen/admin/question_admin_screen.dart';
import 'package:flutterquiz/screen/category_screen.dart';
import 'package:flutterquiz/screen/dashboard.dart';
import 'package:flutterquiz/screen/quiz_finish_screen.dart';
import 'package:flutterquiz/screen/quiz_screen.dart';
import 'package:flutterquiz/screen/quiz_screens.dart';
import 'package:flutterquiz/screen/splash_screen.dart';
import 'package:flutterquiz/service/api/auth_service.dart';
import 'package:flutterquiz/util/router_path.dart';

class Routerr {
  static Route<dynamic> generateRouter(RouteSettings settings) {
    switch (settings.name) {
      case LoginScreen:
        return MaterialPageRoute(
            builder: (BuildContext context) => BlocProvider(
                  create: (_) => AuthBloc(
                    AuthService(),
                  ),
                  child: LoginPage(),
                ));
      case AdminDashboardScreens:
        return MaterialPageRoute(
            builder: (BuildContext context) => AdminDashboardScreen());
      case EditCategoryScreens:
        final argument = settings.arguments;
        return MaterialPageRoute(
            builder: (_) => EditCategoryScreen(
                  category: argument as Category,
                ));
      case AddCategoryScreens:
        return MaterialPageRoute(
            builder: (BuildContext context) => AddCategoryScreen());
      case AddQuestionScreens:
        final args = settings.arguments as Map<String, int>;
        return MaterialPageRoute(
            builder: (_) => AddQuestionScreen(
                  categoryId: args['categoryId']!,
                  idQuestionPackage: args['idQuestionPackage']!,
                ));
      case ResultExamScreens:
        return MaterialPageRoute(builder: (_) => ExamResultScreen());
      case ManageQuestionPackageScreens:
        return MaterialPageRoute(
            builder: (BuildContext context) => ManageQuestionPackageScreen(
                  category: settings.arguments as Category,
                ));
      case CategoryManagerScreens:
        return MaterialPageRoute(
            builder: (BuildContext context) => ManageCategoryScreen());
      case ManageQuestionScreens:
        return MaterialPageRoute(
            builder: (BuildContext context) => ManageQuestionScreen());
      case RegisterScreen:
        return MaterialPageRoute(
            builder: (BuildContext context) => BlocProvider(
                  create: (_) => AuthBloc(
                    AuthService(),
                  ),
                  child: RegisterPage(),
                ));
      case ManageUserScreenss:
        return MaterialPageRoute(
            builder: (BuildContext context) => ManageUserScreen());
      case SplashScreen:
        return MaterialPageRoute(
            builder: (BuildContext context) => SplashPage());
      case CreatedTestListScreens:
        return MaterialPageRoute(
            builder: (BuildContext context) => CreatedTestListScreen());
      case DashBoardScreen:
        return MaterialPageRoute(
            builder: (BuildContext context) => DashboardPage());
      case CreateExamScreens:
        return MaterialPageRoute(
            builder: (BuildContext context) => CreateExamScreen());
      case AddQuestionPackageScreens:
        final args = settings.arguments as Map<String, int?>;
        return MaterialPageRoute(
            builder: (_) => AddQuestionPackageScreen(
                  categoryId: args['categoryId']!,
                ));
      case QuizScreen:
        final argument = settings.arguments;
        return MaterialPageRoute(
          builder: (_) => QuizPage(
            difficult: argument as String,
            listQuestion: argument as List<Question>,
            id: int.parse(argument as String),
          ),
        );
      case QuizScreenH:
        final args = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(
            builder: (_) => QuizPageApi(
                  categoryId: args['categoryId']!,
                  questionId: args['questionId']!,
                  idTest: args['idTest']!,
                  isTest: args['isTest']!,
                  timeLimitMinutes: args['timeLimitMinutes']!,
                  numberQuestion: args['numberQuestion'] ?? null,
                  // Pass the list of questions here
                ));
      case UserExamResultScreenss:
        return MaterialPageRoute(
            builder: (BuildContext context) => UserExamResultScreen());
      case QuestionPackageListScreens:
        final args = settings.arguments as Map<String, int>;
        return MaterialPageRoute(
            builder: (_) => QuestionPackageListScreen(
                  categoryId: args['categoryId']!,
                  categoryName: '${args['categoryName']}',
                ));
      case QuizFinishScreen:
        final argument = settings.arguments;
        return MaterialPageRoute(
            builder: (_) => QuizFinishPage(title: argument as String?));
      default:
        throw Exception('Route not found: ${settings.name}');
    }
  }
}
