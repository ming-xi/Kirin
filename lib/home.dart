import 'dart:convert';
import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kirin/extensions.dart';
import 'package:kirin/preferences.dart';
import 'package:sprintf/sprintf.dart';

const String paletteKeyRegex = "[a-fA-F0-9]{8}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{12}-dark-theme-colors";
const String constTemplate = "static const Color %s = Color(0x%s);";

class HomePage extends StatefulWidget {
  const HomePage();

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  TextEditingController controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Sketch Palette Extractor"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.max,
            children: [
              Expanded(
                child: TextField(
                  style: Theme.of(context).textTheme.bodyText2!.copyWith(fontFamily: 'mono'),
                  controller: controller,
                  keyboardType: TextInputType.multiline,
                  maxLines: 50,
                  decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(16.0)))),
                ),
              ),
              SizedBox(
                height: 24,
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ElevatedButton(
                    onPressed: () async {
                      File? file = await selectFile();
                      if (file == null) {
                        return;
                      }
                      // File file = File("/Users/xumingke/Downloads/HOOH 220214.sketch");
                      readFile(file);
                    },
                    child: Text("Select Sketch file"),
                  ),
                  SizedBox(
                    width: 16,
                  ),
                  ElevatedButton(
                      onPressed: () async {
                        await Clipboard.setData(ClipboardData(text: controller.text));
                        showSnackBar(context, "Copied!");
                      },
                      child: Text("Copy to clipboard"))
                ],
              ),
              SizedBox(
                height: 48,
              )
            ],
          ),
        ),
      ),
    );
  }

  Future<File?> selectFile() async {
    String directory = preferences.getString(Preferences.keyLastDirectoryPath, def: "/")!;
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      initialDirectory: directory,
      type: FileType.custom,
      allowedExtensions: ['sketch'],
    );
    String? path = result?.paths[0];
    debugPrint("path=$path");
    if (path != null) {
      directory = path.substring(0, path.lastIndexOf("/"));
      preferences.putString(Preferences.keyLastDirectoryPath, directory);
    }
    return path == null ? null : File(path);
  }

  void readFile(File file) {
    final inputStream = InputFileStream(file.path);
    final archive = ZipDecoder().decodeBuffer(inputStream);
    // For all of the entries in the archive
    for (ArchiveFile file in archive.files) {
      // If it's a file and not a directory
      if (file.isFile) {
        if (file.name == "document.json") {
          String content = String.fromCharCodes(file.content);
          Map<String, Map<String, Color>>? palette = getPalette(content);
          if (palette != null) {
            setState(() {
              String text = "";
              for (var key in palette.keys) {
                text += sprintf(constTemplate, [getFixedColorName(key, true), palette[key]!['light']!.toHex(leadingHashSign: false).toUpperCase()]) + "\n";
              }
              text += "\n";
              for (var key in palette.keys) {
                text += sprintf(constTemplate, [getFixedColorName(key, false), palette[key]!['dark']!.toHex(leadingHashSign: false).toUpperCase()]) + "\n";
              }
              controller.text = text;
            });
          }
          break;
        }
      }
    }
    inputStream.close();
  }

  String getFixedColorName(String name, bool light) {
    return (name.toLowerCase() + "_" + (light ? "light" : "dark"))
        .replaceAll("-", "_")
        .replaceAll("/", "_")
        .replaceAll("+", "_")
        .replaceAll("=", "_")
        .replaceAll("*", "_")
        .replaceAll(".", "_")
        .replaceAll(":", "_");
  }

  Map<String, Map<String, Color>>? getPalette(String content) {
    RegExpMatch? match = RegExp(paletteKeyRegex).firstMatch(content);
    if (match == null) {
      showSnackBar(context, "Invalid Sketch file");
      return null;
    }
    String themeKey = content.substring(match.start, match.end);
    Map decodedContent = json.decode(content);
    List darkColors = json.decode(decodedContent['userInfo']['io.eduardogomez.sketch-dark-mode'][themeKey]);

    Map<String, Map<String, Color>> resultMap = Map.fromEntries(darkColors.map((e) => MapEntry(e['name'], {'dark': getDarkColor(e['color'])})));
    List lightColors = decodedContent['sharedSwatches']['objects'];
    lightColors = lightColors.where((e) => resultMap.keys.contains(e['name'])).toList();
    for (var color in lightColors) {
      resultMap[color['name']]!['light'] = getLightColor(color['value']);
    }
    debugPrint(json.encode(resultMap.map((key, value) => MapEntry(key, value.map((key, value) => MapEntry(key, value.toHex(leadingHashSign: true)))))));
    return resultMap;
  }

  Color getLightColor(dynamic input) {
    Map map = input as Map;
    var color = Color.fromARGB(
      getColorValue(map['alpha']),
      getColorValue(map['red']),
      getColorValue(map['green']),
      getColorValue(map['blue']),
    );
    debugPrint("$input->${color.toHex(leadingHashSign: true)}");
    return color;
  }

  int getColorValue(dynamic frag) {
    var res = (256 * frag).toInt();
    if (res == 256) {
      res = 255;
    }
    return res;
  }

  Color getDarkColor(String input) {
    //input format is #rrggbbaa
    Color color = HexColor.fromHex(input);
    if (input.length >= 8) {
      var color2 = Color.fromARGB(color.blue, color.alpha, color.red, color.green);
      // debugPrint("$input->${color2.toHex(leadingHashSign: true)}");
      return color2;
    } else {
      // debugPrint("$input->${color.toHex(leadingHashSign: true)}");
      return color;
    }
  }

  void showSnackBar(BuildContext context, String message) {
    final snackBar = SnackBar(
      duration: Duration(seconds: 2),
      content: Text(message),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }
}
