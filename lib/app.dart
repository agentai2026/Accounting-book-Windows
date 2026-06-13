import 'package:flutter/material.dart';

import 'package:flutter_localizations/flutter_localizations.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';



import 'package:ezbookkeeping_desktop/core/constants/app_constants.dart';

import 'package:ezbookkeeping_desktop/desktop/providers/settings_provider.dart';

import 'package:ezbookkeeping_desktop/desktop/theme/app_theme.dart';

import 'package:ezbookkeeping_desktop/desktop/widgets/layout/desktop_shell.dart';

import 'package:ezbookkeeping_desktop/routes.dart';



class EzBookkeepingApp extends ConsumerWidget {

  const EzBookkeepingApp({super.key});



  @override

  Widget build(BuildContext context, WidgetRef ref) {

    final router = ref.watch(routerProvider);

    final themeMode = ref.watch(themeModeProvider);



    return DesktopShell(

      child: MaterialApp.router(

        title: AppConstants.appName,

        debugShowCheckedModeBanner: false,

        theme: AppTheme.light(),

        darkTheme: AppTheme.dark(),

        themeMode: themeMode,

        routerConfig: router,

        locale: const Locale('zh', 'CN'),

        supportedLocales: const [

          Locale('zh', 'CN'),

          Locale('en', 'US'),

        ],

        localizationsDelegates: const [

          GlobalMaterialLocalizations.delegate,

          GlobalWidgetsLocalizations.delegate,

          GlobalCupertinoLocalizations.delegate,

        ],

      ),

    );

  }

}


