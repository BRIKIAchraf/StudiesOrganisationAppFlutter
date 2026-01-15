> Task :gradle:compileJava NO-SOURCE
> Task :gradle:compileGroovy UP-TO-DATE
> Task :gradle:pluginDescriptors UP-TO-DATE
> Task :gradle:processResources UP-TO-DATE
> Task :gradle:classes UP-TO-DATE
> Task :gradle:jar UP-TO-DATE
WARNING: We recommend using a newer Android Gradle plugin to use compileSdk = 35

This Android Gradle plugin (8.2.1) was tested up to compileSdk = 34.

You are strongly encouraged to update your project to use a newer
Android Gradle plugin that has been tested with compileSdk = 35.

If you are already using the latest version of the Android Gradle plugin,
you may need to wait until a newer version with support for compileSdk = 35 is available.

To suppress this warning, add/update
    android.suppressUnsupportedCompileSdk=35
to this project's gradle.properties.
> Task :app:preBuild UP-TO-DATE
> Task :app:preDebugBuild UP-TO-DATE
> Task :app:mergeDebugNativeDebugMetadata NO-SOURCE
> Task :app:checkKotlinGradlePluginConfigurationErrors

> Task :app:compileFlutterBuildDebug
lib/providers/courses_provider.dart:70:62: Error: The getter 'courseId' isn't defined for the class 'StudySession'.
 - 'StudySession' is from 'package:study_planner/models/study_session.dart' ('lib/models/study_session.dart').
Try correcting the name to the name of an existing getter, or defining a getter or field named 'courseId'.
            final usersSessions = allSessions.where((s) => s.courseId == c.id).toList();
                                                             ^^^^^^^^
Target kernel_snapshot_program failed: Exception


> Task :app:compileFlutterBuildDebug FAILED

FAILURE: Build failed with an exception.

* What went wrong:
Execution failed for task ':app:compileFlutterBuildDebug'.
> Process 'command 'D:\Mobile project\flutter\bin\flutter.bat'' finished with non-zero exit value 1

* Try:
> Run with --stacktrace option to get the stack trace.
> Run with --info or --debug option to get more log output.
> Run with --scan to get full insights.
> Get more help at https://help.gradle.org.

BUILD FAILED in 18s
6 actionable tasks: 2 executed, 4 up-to-date
