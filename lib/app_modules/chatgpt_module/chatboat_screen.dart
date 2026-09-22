import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ChatScreen extends StatefulWidget {
  const ChatScreen({
    super.key,
    required this.userId,
  });

  final int userId;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  // =============================================================
  // CHAT MESSAGES
  // =============================================================

  final List<Map<String, dynamic>> _messages = [
    {
      'text': "Hello! I'm Serene AI. How can I assist you today?",
      'isUser': false,
      'properties': null,
    },
  ];

  // =============================================================
  // TEXT CONTROLLER
  // =============================================================

  final TextEditingController _textController =
      TextEditingController();

  // =============================================================
  // LOADING STATE
  // =============================================================

  bool _isLoading = false;

  // =============================================================
  // CHATBOT API URL
  // =============================================================

  final String chatbotUrl =
      'https://8w873g22-8001.inc1.devtunnels.ms/userapp/chatbot/';

  // =============================================================
  // INIT STATE
  // =============================================================

  @override
  void initState() {
    super.initState();

    debugPrint(
      'ChatScreen userId: ${widget.userId}',
    );
  }

  // =============================================================
  // ADD BOT MESSAGE
  // =============================================================

  void _addBotMessage(
    String text, {
    List<dynamic>? properties,
  }) {
    if (!mounted) return;

    setState(() {
      _messages.insert(0, {
        'text': text,
        'isUser': false,
        'properties': properties,
      });
    });
  }

  // =============================================================
  // ADD USER MESSAGE
  // =============================================================

  void _addUserMessage(String text) {
    if (!mounted) return;

    setState(() {
      _messages.insert(0, {
        'text': text,
        'isUser': true,
        'properties': null,
      });
    });
  }

  // =============================================================
  // CLEAN PROPERTY LIST FROM BACKEND REPLY
  // =============================================================
  //
  // Backend reply:
  //
  // The highest-rated properties in Serene have a rating of 5.0.
  //
  // 1. ABC
  //    Location: Thrissur
  //    Rating: 5.0
  //    Reviews: 4
  //    Rate: ₹500.00
  //
  // We only want:
  //
  // The highest-rated properties in Serene have a rating of 5.0.
  //
  // The actual property information comes from the
  // "properties" JSON array.
  // =============================================================

  String _cleanPropertyReply(String reply) {
    if (reply.trim().isEmpty) {
      return '';
    }

    final RegExp propertyListPattern = RegExp(
      r'\n\s*\d+\.\s*',
    );

    final Match? match =
        propertyListPattern.firstMatch(reply);

    if (match != null) {
      return reply
          .substring(0, match.start)
          .trim();
    }

    return reply.trim();
  }

  // =============================================================
  // SEND MESSAGE TO BACKEND
  // =============================================================

  Future<void> _sendMessageToBackend(
    String message,
  ) async {
    try {
      // ---------------------------------------------------------
      // START LOADING
      // ---------------------------------------------------------

      setState(() {
        _isLoading = true;
      });

      debugPrint(
        '========================================',
      );

      debugPrint(
        'Sending message to Serene AI',
      );

      debugPrint(
        'Message: $message',
      );

      debugPrint(
        '========================================',
      );

      // ---------------------------------------------------------
      // API REQUEST
      // ---------------------------------------------------------

      final response = await http
          .post(
            Uri.parse(chatbotUrl),

            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },

            body: jsonEncode({
              'message': message,
            }),
          )
          .timeout(
            const Duration(
              seconds: 30,
            ),
          );

      debugPrint(
        'Chatbot Status Code: ${response.statusCode}',
      );

      debugPrint(
        'Chatbot Response: ${response.body}',
      );

      if (!mounted) return;

      // =========================================================
      // SUCCESS RESPONSE
      // =========================================================

      if (response.statusCode == 200) {
        // IMPORTANT:
        // Decode response as UTF-8 so ₹ displays correctly.
        final dynamic decodedData =
            jsonDecode(
          utf8.decode(
            response.bodyBytes,
          ),
        );

        // -------------------------------------------------------
        // CHECK RESPONSE FORMAT
        // -------------------------------------------------------

        if (decodedData
            is! Map<String, dynamic>) {
          _addBotMessage(
            "Sorry, I received an invalid response from the server.",
          );

          return;
        }

        // -------------------------------------------------------
        // STATUS
        // -------------------------------------------------------

        final bool status =
            decodedData['status'] == true;

        // -------------------------------------------------------
        // REPLY
        // -------------------------------------------------------

        final String reply =
            (decodedData['reply'] ?? '')
                .toString()
                .trim();

        // -------------------------------------------------------
        // SCOPE
        // -------------------------------------------------------

        final String scope =
            (decodedData['scope'] ?? '')
                .toString()
                .trim();

        // -------------------------------------------------------
        // PROPERTIES
        // -------------------------------------------------------

        final List<dynamic> properties =
            decodedData['properties'] is List
                ? decodedData['properties']
                    as List<dynamic>
                : [];

        debugPrint(
          'Status: $status',
        );

        debugPrint(
          'Scope: $scope',
        );

        debugPrint(
          'Reply: $reply',
        );

        debugPrint(
          'Property Count: ${properties.length}',
        );

        // =======================================================
        // SERENE RESPONSE
        // =======================================================

        if (status && scope == 'serene') {
          String displayReply = reply;

          // If structured properties are available,
          // remove the duplicated property list from reply.
          if (properties.isNotEmpty) {
            displayReply =
                _cleanPropertyReply(reply);
          }

          if (displayReply.isNotEmpty ||
              properties.isNotEmpty) {
            _addBotMessage(
              displayReply,
              properties: properties,
            );
          } else {
            _addBotMessage(
              "Sorry, I couldn't find a suitable answer.",
            );
          }

          return;
        }

        // =======================================================
        // OUTSIDE SERENE
        // =======================================================

        if (scope == 'outside_serene') {
          _addBotMessage(
            reply.isNotEmpty
                ? reply
                : "I'm Serene AI Assistant. I can only help with Serene-related properties, vacation rentals, bookings, hosts, reviews, ratings, payments, availability, and other services available in the Serene platform.",
          );

          return;
        }

        // =======================================================
        // OTHER SUCCESS RESPONSE
        // =======================================================

        if (status) {
          String displayReply = reply;

          if (properties.isNotEmpty) {
            displayReply =
                _cleanPropertyReply(reply);
          }

          if (displayReply.isNotEmpty ||
              properties.isNotEmpty) {
            _addBotMessage(
              displayReply,
              properties: properties,
            );
          } else {
            _addBotMessage(
              "Sorry, I couldn't find a suitable answer.",
            );
          }

          return;
        }

        // =======================================================
        // BACKEND ERROR RESPONSE
        // =======================================================

        _addBotMessage(
          reply.isNotEmpty
              ? reply
              : "Sorry, I couldn't process your request.",
        );
      }

      // =========================================================
      // NON-200 RESPONSE
      // =========================================================

      else {
        debugPrint(
          'Server Error: ${response.statusCode}',
        );

        _addBotMessage(
          "Server error. Please try again later.",
        );
      }
    }

    // ===========================================================
    // CONNECTION / OTHER ERROR
    // ===========================================================

    catch (e) {
      debugPrint(
        'Chatbot Error: $e',
      );

      if (!mounted) return;

      _addBotMessage(
        "Unable to connect to Serene AI. Please check your internet connection and try again.",
      );
    }

    // ===========================================================
    // STOP LOADING
    // ===========================================================

    finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // =============================================================
  // HANDLE USER MESSAGE
  // =============================================================

  Future<void> _handleSubmitted(
    String text,
  ) async {
    final String message =
        text.trim();

    // Don't send empty message
    if (message.isEmpty) {
      return;
    }

    // Don't send while request is running
    if (_isLoading) {
      return;
    }

    // Clear input
    _textController.clear();

    // Display user message
    _addUserMessage(message);

    // Send to backend
    await _sendMessageToBackend(
      message,
    );
  }

  // =============================================================
  // DISPOSE
  // =============================================================

  @override
  void dispose() {
    _textController.dispose();

    super.dispose();
  }

  // =============================================================
  // BUILD
  // =============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      backgroundColor:
          const Color(0xFFFFF9F7),

      // ==========================================================
      // APP BAR
      // ==========================================================

      appBar: AppBar(
        elevation: 0,

        backgroundColor:
            Colors.white,

        centerTitle: true,

        title: const Text(
          "Serene AI",

          style: TextStyle(
            color: Colors.black,
            fontWeight:
                FontWeight.bold,
            fontSize: 24,
          ),
        ),

        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: Colors.black,
          ),

          onPressed: () {
            Navigator.pop(
              context,
            );
          },
        ),
      ),

      // ==========================================================
      // BODY
      // ==========================================================

      body: Column(
        children: [
          // ========================================================
          // CHAT MESSAGE LIST
          // ========================================================

          Expanded(
            child: ListView.builder(
              padding:
                  const EdgeInsets.all(8),

              reverse: true,

              itemCount:
                  _messages.length,

              itemBuilder:
                  (_, int index) {
                final Map<String, dynamic>
                    message =
                    _messages[index];

                return ChatMessage(
                  text:
                      message['text']
                          as String,

                  isUser:
                      message['isUser']
                          as bool,

                  properties:
                      message['properties']
                          as List<dynamic>?,
                );
              },
            ),
          ),

          // ========================================================
          // LOADING INDICATOR
          // ========================================================

          if (_isLoading)
            const Padding(
              padding:
                  EdgeInsets.only(
                left: 20,
                right: 20,
                bottom: 8,
              ),

              child: Align(
                alignment:
                    Alignment.centerLeft,

                child: Row(
                  mainAxisSize:
                      MainAxisSize.min,

                  children: [
                    CircleAvatar(
                      radius: 15,

                      backgroundColor:
                          Colors.blue,

                      child: Icon(
                        Icons
                            .psychology_alt_outlined,
                        color:
                            Colors.white,
                        size: 18,
                      ),
                    ),

                    SizedBox(
                      width: 8,
                    ),

                    Text(
                      "Serene AI is typing...",

                      style: TextStyle(
                        color:
                            Colors.grey,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // ========================================================
          // DIVIDER
          // ========================================================

          const Divider(
            height: 1,
          ),

          // ========================================================
          // INPUT
          // ========================================================

          _buildTextComposer(),
        ],
      ),
    );
  }

  // =============================================================
  // TEXT COMPOSER
  // =============================================================

  Widget _buildTextComposer() {
    return IconTheme(
      data: IconThemeData(
        color: Theme.of(
          context,
        ).colorScheme.secondary,
      ),

      child: Container(
        margin:
            const EdgeInsets.symmetric(
          horizontal: 8,
          vertical: 8,
        ),

        decoration:
            BoxDecoration(
          color:
              Colors.grey[200],

          borderRadius:
              BorderRadius.circular(
            30,
          ),
        ),

        child: Row(
          children: [
            // ====================================================
            // TEXT FIELD
            // ====================================================

            Flexible(
              child: TextField(
                controller:
                    _textController,

                enabled:
                    !_isLoading,

                textInputAction:
                    TextInputAction.send,

                onSubmitted:
                    (value) {
                  _handleSubmitted(
                    value,
                  );
                },

                decoration:
                    const InputDecoration(
                  hintText:
                      "Send a message...",

                  contentPadding:
                      EdgeInsets.symmetric(
                    horizontal: 20,
                  ),

                  border:
                      InputBorder.none,
                ),
              ),
            ),

            // ====================================================
            // SEND BUTTON
            // ====================================================

            IconButton(
              onPressed: _isLoading
                  ? null
                  : () {
                      _handleSubmitted(
                        _textController
                            .text,
                      );
                    },

              icon: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,

                      child:
                          CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(
                      Icons.send,
                      color:
                          Colors.blue,
                      size: 32,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// =================================================================
// CHAT MESSAGE WIDGET
// =================================================================

class ChatMessage
    extends StatefulWidget {
  const ChatMessage({
    required this.text,
    required this.isUser,
    this.properties,
    super.key,
  });

  final String text;

  final bool isUser;

  final List<dynamic>? properties;

  @override
  State<ChatMessage>
      createState() =>
          _ChatMessageState();
}

// =================================================================
// CHAT MESSAGE STATE
// =================================================================

class _ChatMessageState
    extends State<ChatMessage>
    with
        SingleTickerProviderStateMixin {
  late AnimationController
      _animationController;

  // =============================================================
  // INIT
  // =============================================================

  @override
  void initState() {
    super.initState();

    _animationController =
        AnimationController(
      duration:
          const Duration(
        milliseconds: 500,
      ),
      vsync: this,
    );

    _animationController
        .forward();
  }

  // =============================================================
  // DISPOSE
  // =============================================================

  @override
  void dispose() {
    _animationController
        .dispose();

    super.dispose();
  }

  // =============================================================
  // BUILD
  // =============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    return SizeTransition(
      sizeFactor:
          CurvedAnimation(
        parent:
            _animationController,

        curve:
            Curves.easeOut,
      ),

      axisAlignment: 0,

      child: Container(
        margin:
            const EdgeInsets.symmetric(
          vertical: 10,
        ),

        child: Row(
          mainAxisAlignment:
              widget.isUser
                  ? MainAxisAlignment
                      .end
                  : MainAxisAlignment
                      .start,

          crossAxisAlignment:
              CrossAxisAlignment
                  .start,

          children: [
            // ====================================================
            // BOT ICON
            // ====================================================

            if (!widget.isUser) ...[
              const CircleAvatar(
                backgroundColor:
                    Colors.blue,

                child: Icon(
                  Icons
                      .psychology_alt_outlined,
                  color:
                      Colors.white,
                ),
              ),

              const SizedBox(
                width: 8,
              ),
            ],

            // ====================================================
            // MESSAGE + PROPERTY CARDS
            // ====================================================

            Flexible(
              child: Column(
                crossAxisAlignment:
                    widget.isUser
                        ? CrossAxisAlignment
                            .end
                        : CrossAxisAlignment
                            .start,

                children: [
                  // =================================================
                  // MESSAGE BUBBLE
                  // =================================================

                  if (widget
                      .text
                      .isNotEmpty)
                    Container(
                      constraints:
                          BoxConstraints(
                        maxWidth:
                            MediaQuery.of(
                                  context,
                                ).size.width *
                                0.75,
                      ),

                      decoration:
                          BoxDecoration(
                        color: widget
                                .isUser
                            ? Colors
                                .blue[100]
                            : Colors
                                .grey[200],

                        borderRadius:
                            BorderRadius
                                .only(
                          topLeft:
                              const Radius
                                  .circular(
                            20,
                          ),

                          topRight:
                              const Radius
                                  .circular(
                            20,
                          ),

                          bottomLeft:
                              widget
                                      .isUser
                                  ? const Radius
                                      .circular(
                                      20,
                                    )
                                  : Radius.zero,

                          bottomRight:
                              widget
                                      .isUser
                                  ? Radius.zero
                                  : const Radius
                                      .circular(
                                      20,
                                    ),
                        ),
                      ),

                      padding:
                          const EdgeInsets
                              .all(
                        12,
                      ),

                      child: Text(
                        widget.text,

                        style:
                            TextStyle(
                          color: widget
                                  .isUser
                              ? Colors
                                  .blue[900]
                              : Colors.black,

                          fontSize: 16,

                          height: 1.4,
                        ),
                      ),
                    ),

                  // =================================================
                  // PROPERTY CARDS
                  // =================================================

                  if (!widget.isUser &&
                      widget.properties !=
                          null &&
                      widget.properties!
                          .isNotEmpty)
                    const SizedBox(
                      height: 8,
                    ),

                  if (!widget.isUser &&
                      widget.properties !=
                          null &&
                      widget.properties!
                          .isNotEmpty)
                    ...widget
                        .properties!
                        .map(
                      (property) {
                        if (property
                            is Map<String,
                                dynamic>) {
                          return _buildPropertyCard(
                            property,
                          );
                        }

                        return const SizedBox();
                      },
                    ),
                ],
              ),
            ),

            // ====================================================
            // USER ICON
            // ====================================================

            if (widget.isUser) ...[
              const SizedBox(
                width: 8,
              ),

              const CircleAvatar(
                backgroundColor:
                    Colors.green,

                child: Icon(
                  Icons.person,
                  color:
                      Colors.white,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // =============================================================
  // PROPERTY CARD
  // =============================================================

  Widget _buildPropertyCard(
    Map<String, dynamic> property,
  ) {
    // ===========================================================
    // PROPERTY VALUES
    // ===========================================================

    final String propertyName =
        (property[
                    'property_name'] ??
                'N/A')
            .toString();

    final String place =
        (property['place'] ??
                'N/A')
            .toString();

    final String propertyType =
        (property[
                    'property_type'] ??
                'N/A')
            .toString();

    final String rating =
        _formatNumber(
      property['rating'],
    );

    final String reviewCount =
        (property[
                    'review_count'] ??
                0)
            .toString();

    final String rate =
        _formatRate(
      property['rate'],
    );

    // ===========================================================
    // PROPERTY CARD
    // ===========================================================

    return Container(
      width: double.infinity,

      margin:
          const EdgeInsets.only(
        top: 8,
        bottom: 8,
      ),

      padding:
          const EdgeInsets.all(
        14,
      ),

      decoration:
          BoxDecoration(
        color:
            Colors.white,

        borderRadius:
            BorderRadius.circular(
          16,
        ),

        border:
            Border.all(
          color:
              Colors.grey.shade300,
        ),

        boxShadow: [
          BoxShadow(
            color: Colors.black
                .withOpacity(
              0.05,
            ),

            blurRadius: 5,

            offset:
                const Offset(
              0,
              2,
            ),
          ),
        ],
      ),

      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment
                .start,

        children: [
          // =====================================================
          // PROPERTY NAME
          // =====================================================

          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets
                        .all(
                  8,
                ),

                decoration:
                    BoxDecoration(
                  color: Colors.blue
                      .withOpacity(
                    0.1,
                  ),

                  borderRadius:
                      BorderRadius
                          .circular(
                    10,
                  ),
                ),

                child:
                    const Icon(
                  Icons.home_outlined,
                  color:
                      Colors.blue,
                  size: 22,
                ),
              ),

              const SizedBox(
                width: 10,
              ),

              Expanded(
                child: Text(
                  propertyName,

                  style:
                      const TextStyle(
                    fontSize: 18,
                    fontWeight:
                        FontWeight.bold,
                    color:
                        Colors.black87,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(
            height: 14,
          ),

          // =====================================================
          // LOCATION
          // =====================================================

          _propertyInfoRow(
            icon:
                Icons.location_on_outlined,

            title:
                'Location',

            value:
                place,
          ),

          const SizedBox(
            height: 10,
          ),

          // =====================================================
          // PROPERTY TYPE
          // =====================================================

          _propertyInfoRow(
            icon:
                Icons.category_outlined,

            title:
                'Property Type',

            value:
                propertyType,
          ),

          const SizedBox(
            height: 10,
          ),

          // =====================================================
          // RATING
          // =====================================================

          _propertyInfoRow(
            icon:
                Icons.star_outline,

            title:
                'Rating',

            value:
                rating,
          ),

          const SizedBox(
            height: 10,
          ),

          // =====================================================
          // REVIEWS
          // =====================================================

          _propertyInfoRow(
            icon:
                Icons.reviews_outlined,

            title:
                'Reviews',

            value:
                reviewCount,
          ),

          const SizedBox(
            height: 10,
          ),

          // =====================================================
          // RATE
          // =====================================================

          _propertyInfoRow(
            icon:
                Icons.currency_rupee,

            title:
                'Rate',

            value:
                rate,
          ),
        ],
      ),
    );
  }

  // =============================================================
  // PROPERTY INFORMATION ROW
  // =============================================================

  Widget _propertyInfoRow({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Row(
      crossAxisAlignment:
          CrossAxisAlignment
              .start,

      children: [
        // -------------------------------------------------------
        // ICON
        // -------------------------------------------------------

        Icon(
          icon,
          size: 20,
          color:
              Colors.grey[700],
        ),

        const SizedBox(
          width: 10,
        ),

        // -------------------------------------------------------
        // TITLE + VALUE
        // -------------------------------------------------------

        Expanded(
          child: RichText(
            text:
                TextSpan(
              children: [
                TextSpan(
                  text:
                      '$title: ',

                  style:
                      const TextStyle(
                    color:
                        Colors.black87,

                    fontWeight:
                        FontWeight
                            .w600,

                    fontSize: 14,
                  ),
                ),

                TextSpan(
                  text:
                      value,

                  style:
                      const TextStyle(
                    color:
                        Colors.black87,

                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // =============================================================
  // FORMAT NUMBER
  // =============================================================

  String _formatNumber(
    dynamic value,
  ) {
    if (value == null) {
      return 'N/A';
    }

    if (value is double) {
      return value.toStringAsFixed(
        value % 1 == 0
            ? 0
            : 1,
      );
    }

    if (value is int) {
      return value.toString();
    }

    final double? number =
        double.tryParse(
      value.toString(),
    );

    if (number == null) {
      return value.toString();
    }

    return number.toStringAsFixed(
      number % 1 == 0
          ? 0
          : 1,
    );
  }

  // =============================================================
  // FORMAT RATE
  // =============================================================

  String _formatRate(
    dynamic value,
  ) {
    if (value == null) {
      return '₹0.00';
    }

    final double? amount =
        double.tryParse(
      value.toString(),
    );

    if (amount == null) {
      return '₹${value.toString()}';
    }

    return '₹${amount.toStringAsFixed(2)}';
  }
}