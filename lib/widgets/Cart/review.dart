import 'dart:convert';

import 'package:dittox/utils/color_pallets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart' as http;

import '../../utils/dynamicSizing.dart';

class ReviewWidget extends StatefulWidget {
  final String id;
  final String shopId;
  final String accessToken;
  const ReviewWidget({
    super.key,
    required this.id,
    required this.accessToken,
    required this.shopId,
  });
  @override
  State<ReviewWidget> createState() => _ReviewWidgetState();
}

class _ReviewWidgetState extends State<ReviewWidget> {
  final TextEditingController reviewController = TextEditingController();
  double rating = 1.0;
  bool _isLoading = false;

  @override
  void dispose() {
    reviewController.dispose();
    super.dispose();
  }

  Future<void> sendReview(
    double totalScreenHeight,
    double totalScreenWidth,
  ) async {
    setState(() => _isLoading = true);
    try {
      final url =
          'https://dittox.in/xerox/v1/store/addReview/${widget.shopId},${widget.id}';
      final requestBody = {
        "rating": rating.toInt(),
        "review": reviewController.text,
      };
      final response = await http.post(
        Uri.parse(url),
        headers: {
          "Content-Type": "application/json",
          'X-auth-token': 'bearer ${widget.accessToken}',
        },
        body: jsonEncode(requestBody),
      );

      if (!mounted) return;
      final jsonResponse = jsonDecode(response.body);
      final responseCode = jsonResponse["responseCode"].toString();
      if (responseCode == "OK") {
        _showSnackBar(
          totalScreenHeight,
          totalScreenWidth,
          "Your Review has been successfully recorded",
          Colors.green,
        );
      } else {
        throw Exception("Something went wrong");
      }
    } catch (e) {
      if (!mounted) return;
      _showSnackBar(
        totalScreenHeight,
        totalScreenWidth,
        e.toString(),
        Colors.red,
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(
    double totalScreenHeight,
    double totalScreenWidth,
    String message,
    Color iconColor,
  ) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          backgroundColor: ColorPallets.deepBlue,
          content: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              FaIcon(
                FontAwesomeIcons.triangleExclamation,
                color: iconColor,
              ),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    message,
                    style: TextStyle(
                      fontSize: calculateDynamicFontSize(
                        totalScreenHeight: totalScreenHeight,
                        totalScreenWidth: totalScreenWidth,
                        currentFontSize: 18,
                      ),
                      fontStyle: FontStyle.normal,
                      color: ColorPallets.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final mqsz = MediaQuery.sizeOf(context);
    final double totalScreenHeight = mqsz.height;
    final double totalScreenWidth = mqsz.width;
    return Container(
      margin: EdgeInsets.symmetric(
        vertical: calculateDynamicFontSize(
          totalScreenHeight: totalScreenHeight,
          totalScreenWidth: totalScreenWidth,
          currentFontSize: 5,
        ),
        horizontal: calculateDynamicFontSize(
          totalScreenHeight: totalScreenHeight,
          totalScreenWidth: totalScreenWidth,
          currentFontSize: 10,
        ),
      ),
      padding: EdgeInsets.all(
        calculateDynamicFontSize(
          totalScreenHeight: totalScreenHeight,
          totalScreenWidth: totalScreenWidth,
          currentFontSize: 16,
        ),
      ),
      decoration: BoxDecoration(
        border: Border.all(color: ColorPallets.deepBlue),
        borderRadius: BorderRadius.circular(
          calculateDynamicFontSize(
            totalScreenHeight: totalScreenHeight,
            totalScreenWidth: totalScreenWidth,
            currentFontSize: 12,
          ),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          TextField(
            controller: reviewController,
            decoration: const InputDecoration(
              hoverColor: ColorPallets.deepBlue,
              hintText: 'Write a review...',
            ),
          ),
          SizedBox(
            height: calculateDynamicFontSize(
              totalScreenHeight: totalScreenHeight,
              totalScreenWidth: totalScreenWidth,
              currentFontSize: 20,
            ),
          ),
          RatingBar.builder(
            initialRating: rating,
            minRating: 1,
            direction: Axis.horizontal,
            allowHalfRating: false,
            itemCount: 5,
            itemSize: calculateDynamicFontSize(
              totalScreenHeight: totalScreenHeight,
              totalScreenWidth: totalScreenWidth,
              currentFontSize: 35,
            ),
            unratedColor: Colors.amber.shade100.withValues(alpha: 0.7),
            itemPadding: EdgeInsets.symmetric(
              horizontal: calculateDynamicFontSize(
                totalScreenHeight: totalScreenHeight,
                totalScreenWidth: totalScreenWidth,
                currentFontSize: 4,
              ),
            ),
            itemBuilder: (context, _) => const Icon(
              Icons.star,
              color: Colors.amber,
            ),
            onRatingUpdate: (newRating) {
              setState(() => rating = newRating);
            },
          ),
          SizedBox(
            height: calculateDynamicFontSize(
              totalScreenHeight: totalScreenHeight,
              totalScreenWidth: totalScreenWidth,
              currentFontSize: 10,
            ),
          ),
          ElevatedButton(
            onPressed: () => sendReview(totalScreenHeight, totalScreenWidth),
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: ColorPallets.deepBlue,
                    ),
                  )
                : Text(
                    'Submit',
                    style: TextStyle(
                      color: ColorPallets.deepBlue,
                      fontSize: calculateDynamicFontSize(
                        totalScreenHeight: totalScreenHeight,
                        totalScreenWidth: totalScreenWidth,
                        currentFontSize: 18,
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
