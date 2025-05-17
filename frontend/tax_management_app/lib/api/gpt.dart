import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

// import 'package:dart_openai/dart_openai.dart';
import 'package:flutter/foundation.dart';
// import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

// Prompt template that will be used to be sent to OpenAPI server when user capture an image
String imageProcessingPrompt =
    """You are a medical practictioner and an expert in analzying medical related images working for a very reputed hospital. You will be provided with images and you need to identify the anomalies, any disease or health issues. You need to generate the result in detailed manner. Write all the findings, next steps, recommendation. You only need to respond if the image is related to a human body and health issues. You must have to answer but also write a disclaimer saying that \"Consult with a Doctor before making any decisions\". 
    
    I want this point in your response: 
    1. Code (If you are unable to analyze the image, return 0. Else, 1)
    
    2. Name of finding (if you can't state in detail, it is okay to state generally. E.g: acne, scar, etc)

    3. Explanation of finding

    4. Next Steps

    5. Recommendations

    6. Disclaimer

    Give me answer in JSON. The response will look like this: 
     {
      "code": "1",
      "name of finding": "Scar",
      "explanation of finding": "The image shows a raised scar on the skin, which may indicate a previous injury or surgical procedure. Scars can form as part of the healing process after skin damage.",
      "next steps": "Consult a dermatologist for a detailed evaluation of the scar, especially if there are concerns about appearance or sensitivity.",
      "recommendations": "Consider scar management options such as silicone gel sheets, pressure therapy, or other topical treatments to help improve the appearance of the scar. Also, protect the scar from sun exposure.",
      "disclaimer": "Consult with a Doctor before making any decisions."
    };

    And if you can't analyze the image, the response will look like this:
     {
      "code": "0",
      "message": "Unable to determine based on the provided image.", 
      "disclaimer": "Consult with a Doctor before making any decisions"
    };
    
    Remember, if certain aspects are not clear from the image, it\'s okay to state \'Unable to determine based on the provided image.\' 
    
    Please give me a code too. If you are unable to analyze the image, return 0. Else, 1.

    Please make sure you are not trying to bold, italic or underline any word. Just a plain text.

    Now analyze the image and answer the above questions in the same structured manner defined above.""";

// Prompt template that will be used to be sent to OpenAPI server when user chat in 'Diagnose' tab
String chatSystemPrompt =
    """You are a helpful AI health assistant. Your role is to ask the user about their symptoms, help them better understand potential causes, and provide general guidance. 
However, always remind the user that you are not a substitute for professional medical advice and that they should consult a doctor for a formal diagnosis.

    Please make sure you are not trying to bold, italic or underline any word. Just a plain text.
""";

// Function to encode the image to be used when submit to GPT
Future<String> encodeImage(imagePath) async {
// convert image into file object
  File _imageFile = File(imagePath);

// Read bytes from the file object
  Uint8List _bytes = await _imageFile.readAsBytes();

// base64 encode the bytes
  String base64String = base64.encode(_bytes);

  return Future.value(base64String);
}

// Function to make a HTTP POST request to OpenAPI server to get response about the image
Future<Map<String, dynamic>> imageProcessingGPT4Model(String filename) async {
  Uri url = Uri.parse("https://api.openai.com/v1/chat/completions");
  String base64Image = await encodeImage(filename);
  // String apiAccessToken = dotenv.env["OPENAI_API_KEY"]!;

  // try {
  final response = await http.post(
    url,
    headers: <String, String>{
      // "Authorization": "Bearer $apiAccessToken",
      "Content-Type": "application/json",
    },
    body: jsonEncode({
      'model': "gpt-4o-mini",
      'messages': [
        {'role': 'system', 'content': 'You have to give concise answer'},
        {
          'role': 'user',
          'content': [
            {
              'type': 'text',
              'text': imageProcessingPrompt,
            },
            {
              'type': 'image_url',
              'image_url': {
                'url': 'data:image/jpeg;base64,$base64Image',
              },
            },
          ],
        },
      ],
      'max_tokens': 2000,
    }),
  );

  Map<String, dynamic> resData = jsonDecode(response.body);
  if (response.statusCode == 200) {
    return resData;
  } else {
    return resData;
  }
}

// Function to make a HTTP POST request to OpenAPI server to get response about the message that we have sent
Future<Map<String, dynamic>> chatGPT4Model(List messageHistory) async {
  Uri url = Uri.parse("https://api.openai.com/v1/chat/completions");
  // String apiAccessToken = dotenv.env["OPENAI_API_KEY"]!;

  final response = await http.post(
    url,
    headers: <String, String>{
      // "Authorization": "Bearer $apiAccessToken",
      "Content-Type": "application/json",
    },
    body: jsonEncode({
      'model': "gpt-4o-mini",
      'messages': [
        {'role': 'system', 'content': chatSystemPrompt},
        ...messageHistory
      ],
      'max_tokens': 2000,
    }),
  );

  Map<String, dynamic> resData = jsonDecode(response.body);
  if (response.statusCode == 200) {
    return resData;
  } else {
    return resData;
  }
}

Map<String, String> formatResponse(String value) {
  return {};
}
