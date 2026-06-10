import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/config/injection.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'bloc/notebook/notebook_bloc.dart';
import 'domain/repositories/notebook_repository.dart';

/// Root application widget.
class EduNoteApp extends StatelessWidget {
  const EduNoteApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<NotebookBloc>(
          create: (_) => NotebookBloc(repository: sl<NotebookRepository>()),
        ),
      ],
      child: MaterialApp.router(
        title: 'EduNoteAI',
        debugShowCheckedModeBanner: false,

        // Theme
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: ThemeMode.system,

        // Router
        routerConfig: appRouter,

        // Localization
        supportedLocales: const [
          Locale('tr'),
          Locale('en'),
        ],
        locale: const Locale('tr'),
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
      ),
    );
  }
}
