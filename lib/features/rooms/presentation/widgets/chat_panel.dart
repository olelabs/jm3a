// // // // import 'dart:async';
// // // // import 'package:flutter/material.dart';
// // // // import 'package:flutter_animate/flutter_animate.dart';
// // // // import '../../../../core/extensions/context_ext.dart';
// // // // import '../../../../core/theme/app_colors.dart';
// // // // import '../../../../shared/widgets/cards/user_avatar.dart';
// // // // import '../../domain/room_entity.dart';
// // // // import '../room_provider.dart';

// // // // class ChatPanel extends StatefulWidget {
// // // //   const ChatPanel({super.key, required this.room});
// // // //   final RoomProvider room;

// // // //   @override
// // // //   State<ChatPanel> createState() => _ChatPanelState();
// // // // }

// // // // class _ChatPanelState extends State<ChatPanel> {
// // // //   final _ctrl        = TextEditingController();
// // // //   final _scrollCtrl  = ScrollController();
// // // //   final _focusNode   = FocusNode();
// // // //   bool _showScrollDown = false;

// // // //   @override
// // // //   void initState() {
// // // //     super.initState();
// // // //     widget.room.addListener(_onMessages);
// // // //     _scrollCtrl.addListener(_onScroll);
// // // //   }

// // // //   @override
// // // //   void dispose() {
// // // //     widget.room.removeListener(_onMessages);
// // // //     _scrollCtrl.removeListener(_onScroll);
// // // //     _ctrl.dispose();
// // // //     _scrollCtrl.dispose();
// // // //     _focusNode.dispose();
// // // //     super.dispose();
// // // //   }

// // // //   void _onMessages() {
// // // //     // Auto-scroll only if already at the bottom
// // // //     if (!_showScrollDown) _scrollToBottom();
// // // //   }

// // // //   void _onScroll() {
// // // //     final atBottom = _scrollCtrl.position.pixels >=
// // // //         _scrollCtrl.position.maxScrollExtent - 80;
// // // //     if (atBottom != !_showScrollDown) {
// // // //       setState(() => _showScrollDown = !atBottom);
// // // //     }
// // // //   }

// // // //   void _scrollToBottom({bool animated = true}) {
// // // //     WidgetsBinding.instance.addPostFrameCallback((_) {
// // // //       if (!_scrollCtrl.hasClients) return;
// // // //       if (animated) {
// // // //         _scrollCtrl.animateTo(
// // // //           _scrollCtrl.position.maxScrollExtent,
// // // //           duration: const Duration(milliseconds: 200),
// // // //           curve: Curves.easeOut,
// // // //         );
// // // //       } else {
// // // //         _scrollCtrl.jumpTo(_scrollCtrl.position.maxScrollExtent);
// // // //       }
// // // //     });
// // // //   }

// // // //   Future<void> _send() async {
// // // //     final text = _ctrl.text.trim();
// // // //     if (text.isEmpty) return;
// // // //     _ctrl.clear();
// // // //     await widget.room.sendChatMessage(text);
// // // //     _scrollToBottom();
// // // //   }

// // // //   @override
// // // //   Widget build(BuildContext context) {
// // // //     final room  = widget.room;
// // // //     final l10n  = context.l10n;
// // // //     final theme = context.theme;
// // // //     final isMuted = room.isCurrentUserMuted;
// // // //     final chatOff = !room.settings.chatEnabled;

// // // //     return Column(
// // // //       children: [
// // // //         // System notice if chat is disabled
// // // //         if (chatOff)
// // // //           Container(
// // // //             color: theme.colorScheme.surfaceContainerHighest,
// // // //             padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
// // // //             child: Row(
// // // //               children: [
// // // //                 Icon(Icons.voice_over_off_rounded,
// // // //                     size: 14, color: theme.colorScheme.onSurfaceVariant),
// // // //                 const SizedBox(width: 6),
// // // //                 Text('Chat is disabled for this room',
// // // //                     style: theme.textTheme.bodySmall?.copyWith(
// // // //                         color: theme.colorScheme.onSurfaceVariant)),
// // // //               ],
// // // //             ),
// // // //           ),

// // // //         // Messages
// // // //         Expanded(
// // // //           child: Stack(
// // // //             children: [
// // // //               room.chatMessages.isEmpty
// // // //                   ? Center(
// // // //                       child: Text('No messages yet',
// // // //                           style: theme.textTheme.bodyMedium?.copyWith(
// // // //                               color: theme.colorScheme.onSurfaceVariant)))
// // // //                   : ListView.builder(
// // // //                       controller: _scrollCtrl,
// // // //                       padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
// // // //                       itemCount: room.chatMessages.length,
// // // //                       itemBuilder: (_, i) {
// // // //                         final msg = room.chatMessages[i];
// // // //                         final isMe = msg.userId ==
// // // //                             room.currentMember?.userId;
// // // //                         return _ChatBubble(
// // // //                           message: msg,
// // // //                           isMe: isMe,
// // // //                           showAvatar: i == 0 ||
// // // //                               room.chatMessages[i - 1].userId != msg.userId,
// // // //                         ).animate(delay: 20.ms).fadeIn()
// // // //                             .slideY(begin: 0.05, end: 0);
// // // //                       },
// // // //                     ),

// // // //               // Scroll-to-bottom button
// // // //               if (_showScrollDown)
// // // //                 Positioned(
// // // //                   right: 12, bottom: 12,
// // // //                   child: FloatingActionButton.small(
// // // //                     heroTag: 'scroll_down',
// // // //                     onPressed: _scrollToBottom,
// // // //                     child: const Icon(Icons.keyboard_arrow_down_rounded),
// // // //                   ),
// // // //                 ),
// // // //             ],
// // // //           ),
// // // //         ),

// // // //         // Input bar
// // // //         Container(
// // // //           decoration: BoxDecoration(
// // // //             color: theme.colorScheme.surface,
// // // //             border: Border(
// // // //               top: BorderSide(color: theme.colorScheme.outlineVariant),
// // // //             ),
// // // //           ),
// // // //           padding: EdgeInsets.fromLTRB(
// // // //             12, 8, 12,
// // // //             MediaQuery.viewInsetsOf(context).bottom + 8,
// // // //           ),
// // // //           child: Row(
// // // //             children: [
// // // //               Expanded(
// // // //                 child: TextField(
// // // //                   controller: _ctrl,
// // // //                   focusNode: _focusNode,
// // // //                   enabled: !isMuted && !chatOff,
// // // //                   maxLength: 500,
// // // //                   maxLines: null,
// // // //                   textInputAction: TextInputAction.send,
// // // //                   onSubmitted: (_) => _send(),
// // // //                   decoration: InputDecoration(
// // // //                     hintText: isMuted
// // // //                         ? l10n.chatMuted
// // // //                         : chatOff
// // // //                             ? 'Chat disabled'
// // // //                             : l10n.chatPlaceholder,
// // // //                     counterText: '',
// // // //                     border: OutlineInputBorder(
// // // //                       borderRadius: BorderRadius.circular(20),
// // // //                       borderSide: BorderSide.none,
// // // //                     ),
// // // //                     filled: true,
// // // //                     fillColor: theme.colorScheme.surfaceContainerHighest,
// // // //                     contentPadding: const EdgeInsets.symmetric(
// // // //                         horizontal: 14, vertical: 10),
// // // //                   ),
// // // //                 ),
// // // //               ),
// // // //               const SizedBox(width: 8),
// // // //               _SendButton(
// // // //                   onSend: _send,
// // // //                   isSending: room.isSendingChat,
// // // //                   isDisabled: isMuted || chatOff),
// // // //             ],
// // // //           ),
// // // //         ),
// // // //       ],
// // // //     );
// // // //   }
// // // // }

// // // // class _ChatBubble extends StatelessWidget {
// // // //   const _ChatBubble({
// // // //     required this.message,
// // // //     required this.isMe,
// // // //     this.showAvatar = true,
// // // //   });

// // // //   final ChatMessageEntity message;
// // // //   final bool isMe;
// // // //   final bool showAvatar;

// // // //   @override
// // // //   Widget build(BuildContext context) {
// // // //     final theme = context.theme;

// // // //     if (message.isSystem) {
// // // //       return Padding(
// // // //         padding: const EdgeInsets.symmetric(vertical: 4),
// // // //         child: Center(
// // // //           child: Container(
// // // //             padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
// // // //             decoration: BoxDecoration(
// // // //               color: theme.colorScheme.surfaceContainerHighest,
// // // //               borderRadius: BorderRadius.circular(12),
// // // //             ),
// // // //             child: Text(message.content,
// // // //                 style: theme.textTheme.labelSmall?.copyWith(
// // // //                     color: theme.colorScheme.onSurfaceVariant)),
// // // //           ),
// // // //         ),
// // // //       );
// // // //     }

// // // //     return Padding(
// // // //       padding: const EdgeInsets.only(bottom: 6),
// // // //       child: Row(
// // // //         crossAxisAlignment: CrossAxisAlignment.end,
// // // //         mainAxisAlignment:
// // // //             isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
// // // //         children: [
// // // //           if (!isMe && showAvatar) ...[
// // // //             UserAvatar(
// // // //               avatarUrl: message.avatarUrl,
// // // //               displayName: message.displayName,
// // // //               size: 26,
// // // //             ),
// // // //             const SizedBox(width: 6),
// // // //           ] else if (!isMe)
// // // //             const SizedBox(width: 32),

// // // //           Flexible(
// // // //             child: Column(
// // // //               crossAxisAlignment:
// // // //                   isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
// // // //               children: [
// // // //                 if (!isMe && showAvatar)
// // // //                   Padding(
// // // //                     padding: const EdgeInsets.only(bottom: 2, left: 2),
// // // //                     child: Text(message.displayName,
// // // //                         style: theme.textTheme.labelSmall?.copyWith(
// // // //                             color: theme.colorScheme.onSurfaceVariant)),
// // // //                   ),
// // // //                 Opacity(
// // // //                   opacity: message.isOptimistic ? 0.65 : 1.0,
// // // //                   child: Container(
// // // //                     padding: const EdgeInsets.symmetric(
// // // //                         horizontal: 12, vertical: 8),
// // // //                     decoration: BoxDecoration(
// // // //                       color: isMe
// // // //                           ? theme.colorScheme.primary
// // // //                           : theme.colorScheme.surfaceContainerHighest,
// // // //                       borderRadius: BorderRadius.only(
// // // //                         topLeft: const Radius.circular(14),
// // // //                         topRight: const Radius.circular(14),
// // // //                         bottomLeft:
// // // //                             Radius.circular(isMe ? 14 : 3),
// // // //                         bottomRight:
// // // //                             Radius.circular(isMe ? 3 : 14),
// // // //                       ),
// // // //                     ),
// // // //                     child: Text(
// // // //                       message.content,
// // // //                       style: theme.textTheme.bodyMedium?.copyWith(
// // // //                         color: isMe
// // // //                             ? theme.colorScheme.onPrimary
// // // //                             : theme.colorScheme.onSurface,
// // // //                       ),
// // // //                     ),
// // // //                   ),
// // // //                 ),
// // // //               ],
// // // //             ),
// // // //           ),
// // // //         ],
// // // //       ),
// // // //     );
// // // //   }
// // // // }

// // // // class _SendButton extends StatelessWidget {
// // // //   const _SendButton({
// // // //     required this.onSend,
// // // //     required this.isSending,
// // // //     required this.isDisabled,
// // // //   });

// // // //   final VoidCallback onSend;
// // // //   final bool isSending;
// // // //   final bool isDisabled;

// // // //   @override
// // // //   Widget build(BuildContext context) {
// // // //     final active = !isSending && !isDisabled;
// // // //     return GestureDetector(
// // // //       onTap: active ? onSend : null,
// // // //       child: AnimatedContainer(
// // // //         duration: const Duration(milliseconds: 150),
// // // //         width: 40, height: 40,
// // // //         decoration: BoxDecoration(
// // // //           color: active
// // // //               ? context.colorScheme.primary
// // // //               : context.colorScheme.surfaceContainerHighest,
// // // //           shape: BoxShape.circle,
// // // //         ),
// // // //         child: isSending
// // // //             ? const Center(
// // // //                 child: SizedBox(
// // // //                   width: 16, height: 16,
// // // //                   child: CircularProgressIndicator(
// // // //                       strokeWidth: 2, color: Colors.white),
// // // //                 ))
// // // //             : Icon(Icons.send_rounded,
// // // //                 size: 18,
// // // //                 color: active ? Colors.white : context.colorScheme.onSurfaceVariant),
// // // //       ),
// // // //     );
// // // //   }
// // // // }

// // // import 'dart:async';
// // // import 'package:flutter/material.dart';
// // // import 'package:flutter_animate/flutter_animate.dart';
// // // import '../../../../core/extensions/context_ext.dart';
// // // import '../../../../core/theme/app_colors.dart';
// // // import '../../../../shared/widgets/cards/user_avatar.dart';
// // // import '../../domain/room_entity.dart';
// // // import '../room_provider.dart';

// // // class ChatPanel extends StatefulWidget {
// // //   const ChatPanel({super.key, required this.room});
// // //   final RoomProvider room;

// // //   @override
// // //   State<ChatPanel> createState() => _ChatPanelState();
// // // }

// // // class _ChatPanelState extends State<ChatPanel> {
// // //   final _ctrl = TextEditingController();
// // //   final _scrollCtrl = ScrollController();
// // //   final _focusNode = FocusNode();
// // //   bool _showScrollDown = false;

// // //   @override
// // //   void initState() {
// // //     super.initState();
// // //     widget.room.addListener(_onMessages);
// // //     _scrollCtrl.addListener(_onScroll);
// // //   }

// // //   @override
// // //   void dispose() {
// // //     widget.room.removeListener(_onMessages);
// // //     _scrollCtrl.removeListener(_onScroll);
// // //     _ctrl.dispose();
// // //     _scrollCtrl.dispose();
// // //     _focusNode.dispose();
// // //     super.dispose();
// // //   }

// // //   void _onMessages() {
// // //     // Auto-scroll only if already at the bottom
// // //     if (!_showScrollDown) _scrollToBottom();
// // //   }

// // //   void _onScroll() {
// // //     final atBottom =
// // //         _scrollCtrl.position.pixels >=
// // //         _scrollCtrl.position.maxScrollExtent - 80;
// // //     if (atBottom != !_showScrollDown) {
// // //       setState(() => _showScrollDown = !atBottom);
// // //     }
// // //   }

// // //   void _scrollToBottom({bool animated = true}) {
// // //     WidgetsBinding.instance.addPostFrameCallback((_) {
// // //       if (!_scrollCtrl.hasClients) return;
// // //       if (animated) {
// // //         _scrollCtrl.animateTo(
// // //           _scrollCtrl.position.maxScrollExtent,
// // //           duration: const Duration(milliseconds: 200),
// // //           curve: Curves.easeOut,
// // //         );
// // //       } else {
// // //         _scrollCtrl.jumpTo(_scrollCtrl.position.maxScrollExtent);
// // //       }
// // //     });
// // //   }

// // //   Future<void> _send() async {
// // //     final text = _ctrl.text.trim();
// // //     if (text.isEmpty) return;
// // //     _ctrl.clear();
// // //     await widget.room.sendChatMessage(text);
// // //     _scrollToBottom();
// // //   }

// // //   @override
// // //   Widget build(BuildContext context) {
// // //     final room = widget.room;
// // //     final l10n = context.l10n;
// // //     final theme = context.theme;
// // //     final isMuted = room.isCurrentUserMuted;
// // //     final chatOff = !room.settings.chatEnabled;

// // //     return SizedBox.expand(
// // //       child: Column(
// // //         children: [
// // //           // System notice if chat is disabled
// // //           if (chatOff)
// // //             Container(
// // //               color: theme.colorScheme.surfaceContainerHighest,
// // //               padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
// // //               child: Row(
// // //                 children: [
// // //                   Icon(
// // //                     Icons.voice_over_off_rounded,
// // //                     size: 14,
// // //                     color: theme.colorScheme.onSurfaceVariant,
// // //                   ),
// // //                   const SizedBox(width: 6),
// // //                   Text(
// // //                     'Chat is disabled for this room',
// // //                     style: theme.textTheme.bodySmall?.copyWith(
// // //                       color: theme.colorScheme.onSurfaceVariant,
// // //                     ),
// // //                   ),
// // //                 ],
// // //               ),
// // //             ),

// // //           // Messages
// // //           Expanded(
// // //             child: Stack(
// // //               children: [
// // //                 room.chatMessages.isEmpty
// // //                     ? Center(
// // //                         child: Text(
// // //                           'No messages yet',
// // //                           style: theme.textTheme.bodyMedium?.copyWith(
// // //                             color: theme.colorScheme.onSurfaceVariant,
// // //                           ),
// // //                         ),
// // //                       )
// // //                     : ListView.builder(
// // //                         controller: _scrollCtrl,
// // //                         padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
// // //                         itemCount: room.chatMessages.length,
// // //                         itemBuilder: (_, i) {
// // //                           final msg = room.chatMessages[i];
// // //                           final isMe = msg.userId == room.currentMember?.userId;
// // //                           return _ChatBubble(
// // //                                 message: msg,
// // //                                 isMe: isMe,
// // //                                 showAvatar:
// // //                                     i == 0 ||
// // //                                     room.chatMessages[i - 1].userId !=
// // //                                         msg.userId,
// // //                               )
// // //                               .animate(delay: 20.ms)
// // //                               .fadeIn()
// // //                               .slideY(begin: 0.05, end: 0);
// // //                         },
// // //                       ),

// // //                 // Scroll-to-bottom button
// // //                 if (_showScrollDown)
// // //                   Positioned(
// // //                     right: 12,
// // //                     bottom: 12,
// // //                     child: FloatingActionButton.small(
// // //                       heroTag: 'scroll_down',
// // //                       onPressed: _scrollToBottom,
// // //                       child: const Icon(Icons.keyboard_arrow_down_rounded),
// // //                     ),
// // //                   ),
// // //               ],
// // //             ),
// // //           ),

// // //           // Input bar
// // //           Container(
// // //             decoration: BoxDecoration(
// // //               color: theme.colorScheme.surface,
// // //               border: Border(
// // //                 top: BorderSide(color: theme.colorScheme.outlineVariant),
// // //               ),
// // //             ),
// // //             padding: EdgeInsets.fromLTRB(
// // //               12,
// // //               8,
// // //               12,
// // //               MediaQuery.viewInsetsOf(context).bottom + 8,
// // //             ),
// // //             child: Row(
// // //               children: [
// // //                 Expanded(
// // //                   child: TextField(
// // //                     controller: _ctrl,
// // //                     focusNode: _focusNode,
// // //                     enabled: !isMuted && !chatOff,
// // //                     maxLength: 500,
// // //                     maxLines: null,
// // //                     textInputAction: TextInputAction.send,
// // //                     onSubmitted: (_) => _send(),
// // //                     decoration: InputDecoration(
// // //                       hintText: isMuted
// // //                           ? l10n.chatMuted
// // //                           : chatOff
// // //                           ? 'Chat disabled'
// // //                           : l10n.chatPlaceholder,
// // //                       counterText: '',
// // //                       border: OutlineInputBorder(
// // //                         borderRadius: BorderRadius.circular(20),
// // //                         borderSide: BorderSide.none,
// // //                       ),
// // //                       filled: true,
// // //                       fillColor: theme.colorScheme.surfaceContainerHighest,
// // //                       contentPadding: const EdgeInsets.symmetric(
// // //                         horizontal: 14,
// // //                         vertical: 10,
// // //                       ),
// // //                     ),
// // //                   ),
// // //                 ),
// // //                 const SizedBox(width: 8),
// // //                 _SendButton(
// // //                   onSend: _send,
// // //                   isSending: room.isSendingChat,
// // //                   isDisabled: isMuted || chatOff,
// // //                 ),
// // //               ],
// // //             ),
// // //           ),
// // //         ],
// // //       ), // Column
// // //     ); // SizedBox.expand
// // //   }
// // // }

// // // class _ChatBubble extends StatelessWidget {
// // //   const _ChatBubble({
// // //     required this.message,
// // //     required this.isMe,
// // //     this.showAvatar = true,
// // //   });

// // //   final ChatMessageEntity message;
// // //   final bool isMe;
// // //   final bool showAvatar;

// // //   @override
// // //   Widget build(BuildContext context) {
// // //     final theme = context.theme;

// // //     if (message.isSystem) {
// // //       return Padding(
// // //         padding: const EdgeInsets.symmetric(vertical: 4),
// // //         child: Center(
// // //           child: Container(
// // //             padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
// // //             decoration: BoxDecoration(
// // //               color: theme.colorScheme.surfaceContainerHighest,
// // //               borderRadius: BorderRadius.circular(12),
// // //             ),
// // //             child: Text(
// // //               message.content,
// // //               style: theme.textTheme.labelSmall?.copyWith(
// // //                 color: theme.colorScheme.onSurfaceVariant,
// // //               ),
// // //             ),
// // //           ),
// // //         ),
// // //       );
// // //     }

// // //     return Padding(
// // //       padding: const EdgeInsets.only(bottom: 6),
// // //       child: Row(
// // //         crossAxisAlignment: CrossAxisAlignment.end,
// // //         mainAxisAlignment: isMe
// // //             ? MainAxisAlignment.end
// // //             : MainAxisAlignment.start,
// // //         children: [
// // //           if (!isMe && showAvatar) ...[
// // //             UserAvatar(
// // //               avatarUrl: message.avatarUrl,
// // //               displayName: message.displayName,
// // //               size: 26,
// // //             ),
// // //             const SizedBox(width: 6),
// // //           ] else if (!isMe)
// // //             const SizedBox(width: 32),

// // //           Flexible(
// // //             child: Column(
// // //               crossAxisAlignment: isMe
// // //                   ? CrossAxisAlignment.end
// // //                   : CrossAxisAlignment.start,
// // //               children: [
// // //                 if (!isMe && showAvatar)
// // //                   Padding(
// // //                     padding: const EdgeInsets.only(bottom: 2, left: 2),
// // //                     child: Text(
// // //                       message.displayName,
// // //                       style: theme.textTheme.labelSmall?.copyWith(
// // //                         color: theme.colorScheme.onSurfaceVariant,
// // //                       ),
// // //                     ),
// // //                   ),
// // //                 Opacity(
// // //                   opacity: message.isOptimistic ? 0.65 : 1.0,
// // //                   child: Container(
// // //                     padding: const EdgeInsets.symmetric(
// // //                       horizontal: 12,
// // //                       vertical: 8,
// // //                     ),
// // //                     decoration: BoxDecoration(
// // //                       color: isMe
// // //                           ? theme.colorScheme.primary
// // //                           : theme.colorScheme.surfaceContainerHighest,
// // //                       borderRadius: BorderRadius.only(
// // //                         topLeft: const Radius.circular(14),
// // //                         topRight: const Radius.circular(14),
// // //                         bottomLeft: Radius.circular(isMe ? 14 : 3),
// // //                         bottomRight: Radius.circular(isMe ? 3 : 14),
// // //                       ),
// // //                     ),
// // //                     child: Text(
// // //                       message.content,
// // //                       style: theme.textTheme.bodyMedium?.copyWith(
// // //                         color: isMe
// // //                             ? theme.colorScheme.onPrimary
// // //                             : theme.colorScheme.onSurface,
// // //                       ),
// // //                     ),
// // //                   ),
// // //                 ),
// // //               ],
// // //             ),
// // //           ),
// // //         ],
// // //       ),
// // //     );
// // //   }
// // // }

// // // class _SendButton extends StatelessWidget {
// // //   const _SendButton({
// // //     required this.onSend,
// // //     required this.isSending,
// // //     required this.isDisabled,
// // //   });

// // //   final VoidCallback onSend;
// // //   final bool isSending;
// // //   final bool isDisabled;

// // //   @override
// // //   Widget build(BuildContext context) {
// // //     final active = !isSending && !isDisabled;
// // //     return GestureDetector(
// // //       onTap: active ? onSend : null,
// // //       child: AnimatedContainer(
// // //         duration: const Duration(milliseconds: 150),
// // //         width: 40,
// // //         height: 40,
// // //         decoration: BoxDecoration(
// // //           color: active
// // //               ? context.colorScheme.primary
// // //               : context.colorScheme.surfaceContainerHighest,
// // //           shape: BoxShape.circle,
// // //         ),
// // //         child: isSending
// // //             ? const Center(
// // //                 child: SizedBox(
// // //                   width: 16,
// // //                   height: 16,
// // //                   child: CircularProgressIndicator(
// // //                     strokeWidth: 2,
// // //                     color: Colors.white,
// // //                   ),
// // //                 ),
// // //               )
// // //             : Icon(
// // //                 Icons.send_rounded,
// // //                 size: 18,
// // //                 color: active
// // //                     ? Colors.white
// // //                     : context.colorScheme.onSurfaceVariant,
// // //               ),
// // //       ),
// // //     );
// // //   }
// // // }

// // import 'dart:async';
// // import 'package:flutter/material.dart';
// // import 'package:flutter_animate/flutter_animate.dart';
// // import '../../../../core/extensions/context_ext.dart';
// // import '../../../../core/theme/app_colors.dart';
// // import '../../../../shared/widgets/cards/user_avatar.dart';
// // import '../../domain/room_entity.dart';
// // import '../room_provider.dart';

// // // Stable per-user chat colors — deterministic based on userId hash
// // const _kChatColors = [
// //   Color(0xFF4ECDC4),
// //   Color(0xFFA855F7),
// //   Color(0xFFFF6B6B),
// //   Color(0xFF4ADE80),
// //   Color(0xFFFB923C),
// //   Color(0xFF60A5FA),
// //   Color(0xFFF472B6),
// //   Color(0xFFFFD60A),
// //   Color(0xFF34D399),
// //   Color(0xFFC084FC),
// // ];

// // Color _userColor(String userId) =>
// //     _kChatColors[userId.hashCode.abs() % _kChatColors.length];

// // class ChatPanel extends StatefulWidget {
// //   const ChatPanel({super.key, required this.room});
// //   final RoomProvider room;

// //   @override
// //   State<ChatPanel> createState() => _ChatPanelState();
// // }

// // class _ChatPanelState extends State<ChatPanel> {
// //   final _ctrl = TextEditingController();
// //   final _scrollCtrl = ScrollController();
// //   final _focusNode = FocusNode();
// //   bool _showScrollDown = false;

// //   @override
// //   void initState() {
// //     super.initState();
// //     widget.room.addListener(_onMessages);
// //     _scrollCtrl.addListener(_onScroll);
// //   }

// //   @override
// //   void dispose() {
// //     widget.room.removeListener(_onMessages);
// //     _scrollCtrl.removeListener(_onScroll);
// //     _ctrl.dispose();
// //     _scrollCtrl.dispose();
// //     _focusNode.dispose();
// //     super.dispose();
// //   }

// //   void _onMessages() {
// //     // Auto-scroll only if already at the bottom
// //     if (!_showScrollDown) _scrollToBottom();
// //   }

// //   void _onScroll() {
// //     final atBottom =
// //         _scrollCtrl.position.pixels >=
// //         _scrollCtrl.position.maxScrollExtent - 80;
// //     if (atBottom != !_showScrollDown) {
// //       setState(() => _showScrollDown = !atBottom);
// //     }
// //   }

// //   void _scrollToBottom({bool animated = true}) {
// //     WidgetsBinding.instance.addPostFrameCallback((_) {
// //       if (!_scrollCtrl.hasClients) return;
// //       if (animated) {
// //         _scrollCtrl.animateTo(
// //           _scrollCtrl.position.maxScrollExtent,
// //           duration: const Duration(milliseconds: 200),
// //           curve: Curves.easeOut,
// //         );
// //       } else {
// //         _scrollCtrl.jumpTo(_scrollCtrl.position.maxScrollExtent);
// //       }
// //     });
// //   }

// //   Future<void> _send() async {
// //     final text = _ctrl.text.trim();
// //     if (text.isEmpty) return;
// //     _ctrl.clear();
// //     await widget.room.sendChatMessage(text);
// //     _scrollToBottom();
// //   }

// //   @override
// //   Widget build(BuildContext context) {
// //     final room = widget.room;
// //     final l10n = context.l10n;
// //     final theme = context.theme;
// //     final isMuted = room.isCurrentUserMuted;
// //     final chatOff = !room.settings.chatEnabled;

// //     return SizedBox.expand(
// //       child: Column(
// //         children: [
// //           // System notice if chat is disabled
// //           if (chatOff)
// //             Container(
// //               color: theme.colorScheme.surfaceContainerHighest,
// //               padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
// //               child: Row(
// //                 children: [
// //                   Icon(
// //                     Icons.voice_over_off_rounded,
// //                     size: 14,
// //                     color: theme.colorScheme.onSurfaceVariant,
// //                   ),
// //                   const SizedBox(width: 6),
// //                   Text(
// //                     'Chat is disabled for this room',
// //                     style: theme.textTheme.bodySmall?.copyWith(
// //                       color: theme.colorScheme.onSurfaceVariant,
// //                     ),
// //                   ),
// //                 ],
// //               ),
// //             ),

// //           // Messages
// //           Expanded(
// //             child: Stack(
// //               children: [
// //                 room.chatMessages.isEmpty
// //                     ? Center(
// //                         child: Text(
// //                           'No messages yet',
// //                           style: theme.textTheme.bodyMedium?.copyWith(
// //                             color: theme.colorScheme.onSurfaceVariant,
// //                           ),
// //                         ),
// //                       )
// //                     : ListView.builder(
// //                         controller: _scrollCtrl,
// //                         padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
// //                         itemCount: room.chatMessages.length,
// //                         itemBuilder: (_, i) {
// //                           final msg = room.chatMessages[i];
// //                           final isMe = msg.userId == room.currentMember?.userId;
// //                           return _ChatBubble(
// //                                 message: msg,
// //                                 isMe: isMe,
// //                                 showAvatar:
// //                                     i == 0 ||
// //                                     room.chatMessages[i - 1].userId !=
// //                                         msg.userId,
// //                               )
// //                               .animate(delay: 20.ms)
// //                               .fadeIn()
// //                               .slideY(begin: 0.05, end: 0);
// //                         },
// //                       ),

// //                 // Scroll-to-bottom button
// //                 if (_showScrollDown)
// //                   Positioned(
// //                     right: 12,
// //                     bottom: 12,
// //                     child: FloatingActionButton.small(
// //                       heroTag: 'scroll_down',
// //                       onPressed: _scrollToBottom,
// //                       child: const Icon(Icons.keyboard_arrow_down_rounded),
// //                     ),
// //                   ),
// //               ],
// //             ),
// //           ),

// //           // Input bar
// //           Container(
// //             decoration: BoxDecoration(
// //               color: theme.colorScheme.surface,
// //               border: Border(
// //                 top: BorderSide(color: theme.colorScheme.outlineVariant),
// //               ),
// //             ),
// //             padding: EdgeInsets.fromLTRB(
// //               12,
// //               8,
// //               12,
// //               MediaQuery.viewInsetsOf(context).bottom + 8,
// //             ),
// //             child: Row(
// //               children: [
// //                 Expanded(
// //                   child: TextField(
// //                     controller: _ctrl,
// //                     focusNode: _focusNode,
// //                     enabled: !isMuted && !chatOff,
// //                     maxLength: 500,
// //                     maxLines: null,
// //                     textInputAction: TextInputAction.send,
// //                     onSubmitted: (_) => _send(),
// //                     decoration: InputDecoration(
// //                       hintText: isMuted
// //                           ? l10n.chatMuted
// //                           : chatOff
// //                           ? 'Chat disabled'
// //                           : l10n.chatPlaceholder,
// //                       counterText: '',
// //                       border: OutlineInputBorder(
// //                         borderRadius: BorderRadius.circular(20),
// //                         borderSide: BorderSide.none,
// //                       ),
// //                       filled: true,
// //                       fillColor: theme.colorScheme.surfaceContainerHighest,
// //                       contentPadding: const EdgeInsets.symmetric(
// //                         horizontal: 14,
// //                         vertical: 10,
// //                       ),
// //                     ),
// //                   ),
// //                 ),
// //                 const SizedBox(width: 8),
// //                 _SendButton(
// //                   onSend: _send,
// //                   isSending: room.isSendingChat,
// //                   isDisabled: isMuted || chatOff,
// //                 ),
// //               ],
// //             ),
// //           ),
// //         ],
// //       ), // Column
// //     ); // SizedBox.expand
// //   }
// // }

// // class _ChatBubble extends StatelessWidget {
// //   const _ChatBubble({
// //     required this.message,
// //     required this.isMe,
// //     this.showAvatar = true,
// //   });

// //   final ChatMessageEntity message;
// //   final bool isMe;
// //   final bool showAvatar;

// //   @override
// //   Widget build(BuildContext context) {
// //     final theme = context.theme;

// //     if (message.isSystem) {
// //       return Padding(
// //         padding: const EdgeInsets.symmetric(vertical: 4),
// //         child: Center(
// //           child: Container(
// //             padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
// //             decoration: BoxDecoration(
// //               color: theme.colorScheme.surfaceContainerHighest,
// //               borderRadius: BorderRadius.circular(12),
// //             ),
// //             child: Text(
// //               message.content,
// //               style: theme.textTheme.labelSmall?.copyWith(
// //                 color: theme.colorScheme.onSurfaceVariant,
// //               ),
// //             ),
// //           ),
// //         ),
// //       );
// //     }

// //     return Padding(
// //       padding: const EdgeInsets.only(bottom: 6),
// //       child: Row(
// //         crossAxisAlignment: CrossAxisAlignment.end,
// //         mainAxisAlignment: isMe
// //             ? MainAxisAlignment.end
// //             : MainAxisAlignment.start,
// //         children: [
// //           if (!isMe && showAvatar) ...[
// //             UserAvatar(
// //               avatarUrl: message.avatarUrl,
// //               displayName: message.displayName,
// //               size: 26,
// //             ),
// //             const SizedBox(width: 6),
// //           ] else if (!isMe)
// //             const SizedBox(width: 32),

// //           Flexible(
// //             child: Column(
// //               crossAxisAlignment: isMe
// //                   ? CrossAxisAlignment.end
// //                   : CrossAxisAlignment.start,
// //               children: [
// //                 if (!isMe && showAvatar)
// //                   Padding(
// //                     padding: const EdgeInsets.only(bottom: 2, left: 2),
// //                     child: Text(
// //                       message.displayName,
// //                       style: theme.textTheme.labelSmall?.copyWith(
// //                         color: _userColor(message.userId),
// //                         fontWeight: FontWeight.w700,
// //                       ),
// //                     ),
// //                   ),
// //                 Opacity(
// //                   opacity: message.isOptimistic ? 0.65 : 1.0,
// //                   child: Container(
// //                     padding: const EdgeInsets.symmetric(
// //                       horizontal: 12,
// //                       vertical: 8,
// //                     ),
// //                     decoration: BoxDecoration(
// //                       color: isMe
// //                           ? theme.colorScheme.primary
// //                           : _userColor(message.userId).withOpacity(0.18),
// //                       borderRadius: BorderRadius.only(
// //                         topLeft: const Radius.circular(14),
// //                         topRight: const Radius.circular(14),
// //                         bottomLeft: Radius.circular(isMe ? 14 : 3),
// //                         bottomRight: Radius.circular(isMe ? 3 : 14),
// //                       ),
// //                     ),
// //                     child: Text(
// //                       message.content,
// //                       style: theme.textTheme.bodyMedium?.copyWith(
// //                         color: isMe
// //                             ? theme.colorScheme.onPrimary
// //                             : theme.colorScheme.onSurface,
// //                         fontWeight: FontWeight.w500,
// //                       ),
// //                     ),
// //                   ),
// //                 ),
// //               ],
// //             ),
// //           ),
// //         ],
// //       ),
// //     );
// //   }
// // }

// // class _SendButton extends StatelessWidget {
// //   const _SendButton({
// //     required this.onSend,
// //     required this.isSending,
// //     required this.isDisabled,
// //   });

// //   final VoidCallback onSend;
// //   final bool isSending;
// //   final bool isDisabled;

// //   @override
// //   Widget build(BuildContext context) {
// //     final active = !isSending && !isDisabled;
// //     return GestureDetector(
// //       onTap: active ? onSend : null,
// //       child: AnimatedContainer(
// //         duration: const Duration(milliseconds: 150),
// //         width: 40,
// //         height: 40,
// //         decoration: BoxDecoration(
// //           color: active
// //               ? context.colorScheme.primary
// //               : context.colorScheme.surfaceContainerHighest,
// //           shape: BoxShape.circle,
// //         ),
// //         child: isSending
// //             ? const Center(
// //                 child: SizedBox(
// //                   width: 16,
// //                   height: 16,
// //                   child: CircularProgressIndicator(
// //                     strokeWidth: 2,
// //                     color: Colors.white,
// //                   ),
// //                 ),
// //               )
// //             : Icon(
// //                 Icons.send_rounded,
// //                 size: 18,
// //                 color: active
// //                     ? Colors.white
// //                     : context.colorScheme.onSurfaceVariant,
// //               ),
// //       ),
// //     );
// //   }
// // }

// import 'dart:async';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:flutter_animate/flutter_animate.dart';
// import '../../../../core/extensions/context_ext.dart';
// import '../../../../core/theme/app_colors.dart';
// import '../../../../shared/widgets/cards/user_avatar.dart';
// import '../../domain/room_entity.dart';
// import '../room_provider.dart';

// // Stable per-user chat colors — deterministic based on userId hash
// const _kChatColors = [
//   Color(0xFF4ECDC4),
//   Color(0xFFA855F7),
//   Color(0xFFFF6B6B),
//   Color(0xFF4ADE80),
//   Color(0xFFFB923C),
//   Color(0xFF60A5FA),
//   Color(0xFFF472B6),
//   Color(0xFFFFD60A),
//   Color(0xFF34D399),
//   Color(0xFFC084FC),
// ];

// Color _userColor(String userId) =>
//     _kChatColors[userId.hashCode.abs() % _kChatColors.length];

// class ChatPanel extends StatefulWidget {
//   const ChatPanel({super.key, required this.room});
//   final RoomProvider room;

//   @override
//   State<ChatPanel> createState() => _ChatPanelState();
// }

// class _ChatPanelState extends State<ChatPanel> {
//   final _ctrl = TextEditingController();
//   final _scrollCtrl = ScrollController();
//   final _focusNode = FocusNode();
//   bool _showScrollDown = false;
//   ChatMessageEntity? _replyingTo;

//   @override
//   void initState() {
//     super.initState();
//     widget.room.addListener(_onMessages);
//     _scrollCtrl.addListener(_onScroll);
//   }

//   @override
//   void dispose() {
//     widget.room.removeListener(_onMessages);
//     _scrollCtrl.removeListener(_onScroll);
//     _ctrl.dispose();
//     _scrollCtrl.dispose();
//     _focusNode.dispose();
//     super.dispose();
//   }

//   void _onMessages() {
//     // Auto-scroll only if already at the bottom
//     if (!_showScrollDown) _scrollToBottom();
//   }

//   void _onScroll() {
//     final atBottom =
//         _scrollCtrl.position.pixels >=
//         _scrollCtrl.position.maxScrollExtent - 80;
//     if (atBottom != !_showScrollDown) {
//       setState(() => _showScrollDown = !atBottom);
//     }
//   }

//   void _scrollToBottom({bool animated = true}) {
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       if (!_scrollCtrl.hasClients) return;
//       if (animated) {
//         _scrollCtrl.animateTo(
//           _scrollCtrl.position.maxScrollExtent,
//           duration: const Duration(milliseconds: 200),
//           curve: Curves.easeOut,
//         );
//       } else {
//         _scrollCtrl.jumpTo(_scrollCtrl.position.maxScrollExtent);
//       }
//     });
//   }

//   Future<void> _send() async {
//     final text = _ctrl.text.trim();
//     if (text.isEmpty) return;
//     final replyTo = _replyingTo;
//     _ctrl.clear();
//     setState(() => _replyingTo = null);
//     await widget.room.sendChatMessage(text, replyTo: replyTo);
//     _scrollToBottom();
//   }

//   void _startReply(ChatMessageEntity message) {
//     setState(() => _replyingTo = message);
//     _focusNode.requestFocus();
//   }

//   void _cancelReply() => setState(() => _replyingTo = null);

//   @override
//   Widget build(BuildContext context) {
//     final room = widget.room;
//     final l10n = context.l10n;
//     final theme = context.theme;
//     final isMuted = room.isCurrentUserMuted;
//     final chatOff = !room.settings.chatEnabled;

//     return SizedBox.expand(
//       child: Column(
//         children: [
//           // System notice if chat is disabled
//           if (chatOff)
//             Container(
//               color: theme.colorScheme.surfaceContainerHighest,
//               padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//               child: Row(
//                 children: [
//                   Icon(
//                     Icons.voice_over_off_rounded,
//                     size: 14,
//                     color: theme.colorScheme.onSurfaceVariant,
//                   ),
//                   const SizedBox(width: 6),
//                   Text(
//                     'Chat is disabled for this room',
//                     style: theme.textTheme.bodySmall?.copyWith(
//                       color: theme.colorScheme.onSurfaceVariant,
//                     ),
//                   ),
//                 ],
//               ),
//             ),

//           // Messages
//           Expanded(
//             child: Stack(
//               children: [
//                 room.chatMessages.isEmpty
//                     ? Center(
//                         child: Text(
//                           'No messages yet',
//                           style: theme.textTheme.bodyMedium?.copyWith(
//                             color: theme.colorScheme.onSurfaceVariant,
//                           ),
//                         ),
//                       )
//                     : ListView.builder(
//                         controller: _scrollCtrl,
//                         padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
//                         itemCount: room.chatMessages.length,
//                         itemBuilder: (_, i) {
//                           final msg = room.chatMessages[i];
//                           final isMe = msg.userId == room.currentMember?.userId;
//                           return _ChatBubble(
//                                 message: msg,
//                                 isMe: isMe,
//                                 showAvatar:
//                                     i == 0 ||
//                                     room.chatMessages[i - 1].userId !=
//                                         msg.userId,
//                                 onSwipeReply: msg.isSystem
//                                     ? null
//                                     : () => _startReply(msg),
//                               )
//                               .animate(delay: 20.ms)
//                               .fadeIn()
//                               .slideY(begin: 0.05, end: 0);
//                         },
//                       ),

//                 // Scroll-to-bottom button
//                 if (_showScrollDown)
//                   Positioned(
//                     right: 12,
//                     bottom: 12,
//                     child: FloatingActionButton.small(
//                       heroTag: 'scroll_down',
//                       onPressed: _scrollToBottom,
//                       child: const Icon(Icons.keyboard_arrow_down_rounded),
//                     ),
//                   ),
//               ],
//             ),
//           ),

//           // Input bar
//           Container(
//             decoration: BoxDecoration(
//               color: theme.colorScheme.surface,
//               border: Border(
//                 top: BorderSide(color: theme.colorScheme.outlineVariant),
//               ),
//             ),
//             padding: EdgeInsets.fromLTRB(
//               12,
//               8,
//               12,
//               MediaQuery.viewInsetsOf(context).bottom + 8,
//             ),
//             child: Column(
//               mainAxisSize: MainAxisSize.min,
//               crossAxisAlignment: CrossAxisAlignment.stretch,
//               children: [
//                 // Replying-to preview — shown after a swipe-to-reply, with
//                 // a cancel button, same as WhatsApp's compose bar.
//                 if (_replyingTo != null)
//                   Container(
//                     margin: const EdgeInsets.only(bottom: 8),
//                     padding: const EdgeInsets.symmetric(
//                       horizontal: 10,
//                       vertical: 8,
//                     ),
//                     decoration: BoxDecoration(
//                       color: theme.colorScheme.surfaceContainerHighest,
//                       borderRadius: BorderRadius.circular(10),
//                       border: Border(
//                         left: BorderSide(
//                           color: theme.colorScheme.primary,
//                           width: 3,
//                         ),
//                       ),
//                     ),
//                     child: Row(
//                       children: [
//                         Expanded(
//                           child: Column(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             mainAxisSize: MainAxisSize.min,
//                             children: [
//                               Text(
//                                 'Replying to ${_replyingTo!.displayName}',
//                                 style: theme.textTheme.labelSmall?.copyWith(
//                                   fontWeight: FontWeight.w700,
//                                   color: theme.colorScheme.primary,
//                                 ),
//                               ),
//                               Text(
//                                 _replyingTo!.content,
//                                 maxLines: 1,
//                                 overflow: TextOverflow.ellipsis,
//                                 style: theme.textTheme.bodySmall?.copyWith(
//                                   color: theme.colorScheme.onSurfaceVariant,
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),
//                         IconButton(
//                           icon: const Icon(Icons.close_rounded, size: 18),
//                           onPressed: _cancelReply,
//                           padding: EdgeInsets.zero,
//                           constraints: const BoxConstraints(),
//                           visualDensity: VisualDensity.compact,
//                         ),
//                       ],
//                     ),
//                   ),
//                 Row(
//                   children: [
//                     Expanded(
//                       child: TextField(
//                         controller: _ctrl,
//                         focusNode: _focusNode,
//                         enabled: !isMuted && !chatOff,
//                         maxLength: 500,
//                         maxLines: null,
//                         textInputAction: TextInputAction.send,
//                         onSubmitted: (_) => _send(),
//                         decoration: InputDecoration(
//                           hintText: isMuted
//                               ? l10n.chatMuted
//                               : chatOff
//                               ? 'Chat disabled'
//                               : l10n.chatPlaceholder,
//                           counterText: '',
//                           border: OutlineInputBorder(
//                             borderRadius: BorderRadius.circular(20),
//                             borderSide: BorderSide.none,
//                           ),
//                           filled: true,
//                           fillColor: theme.colorScheme.surfaceContainerHighest,
//                           contentPadding: const EdgeInsets.symmetric(
//                             horizontal: 14,
//                             vertical: 10,
//                           ),
//                         ),
//                       ),
//                     ),
//                     const SizedBox(width: 8),
//                     _SendButton(
//                       onSend: _send,
//                       isSending: room.isSendingChat,
//                       isDisabled: isMuted || chatOff,
//                     ),
//                   ],
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ), // Column
//     ); // SizedBox.expand
//   }
// }

// class _ChatBubble extends StatelessWidget {
//   const _ChatBubble({
//     required this.message,
//     required this.isMe,
//     this.showAvatar = true,
//     this.onSwipeReply,
//   });

//   final ChatMessageEntity message;
//   final bool isMe;
//   final bool showAvatar;
//   final VoidCallback? onSwipeReply;

//   @override
//   Widget build(BuildContext context) {
//     final theme = context.theme;

//     if (message.isSystem) {
//       return Padding(
//         padding: const EdgeInsets.symmetric(vertical: 4),
//         child: Center(
//           child: Container(
//             padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
//             decoration: BoxDecoration(
//               color: theme.colorScheme.surfaceContainerHighest,
//               borderRadius: BorderRadius.circular(12),
//             ),
//             child: Text(
//               message.content,
//               style: theme.textTheme.labelSmall?.copyWith(
//                 color: theme.colorScheme.onSurfaceVariant,
//               ),
//             ),
//           ),
//         ),
//       );
//     }

//     final bubble = Padding(
//       padding: const EdgeInsets.only(bottom: 6),
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.end,
//         mainAxisAlignment: isMe
//             ? MainAxisAlignment.end
//             : MainAxisAlignment.start,
//         children: [
//           if (!isMe && showAvatar) ...[
//             UserAvatar(
//               avatarUrl: message.avatarUrl,
//               displayName: message.displayName,
//               size: 26,
//             ),
//             const SizedBox(width: 6),
//           ] else if (!isMe)
//             const SizedBox(width: 32),

//           Flexible(
//             child: Column(
//               crossAxisAlignment: isMe
//                   ? CrossAxisAlignment.end
//                   : CrossAxisAlignment.start,
//               children: [
//                 if (!isMe && showAvatar)
//                   Padding(
//                     padding: const EdgeInsets.only(bottom: 2, left: 2),
//                     child: Text(
//                       message.displayName,
//                       style: theme.textTheme.labelSmall?.copyWith(
//                         color: _userColor(message.userId),
//                         fontWeight: FontWeight.w700,
//                       ),
//                     ),
//                   ),
//                 Opacity(
//                   opacity: message.isOptimistic ? 0.65 : 1.0,
//                   child: Container(
//                     padding: const EdgeInsets.symmetric(
//                       horizontal: 12,
//                       vertical: 8,
//                     ),
//                     decoration: BoxDecoration(
//                       color: isMe
//                           ? theme.colorScheme.primary
//                           : _userColor(message.userId).withOpacity(0.18),
//                       borderRadius: BorderRadius.only(
//                         topLeft: const Radius.circular(14),
//                         topRight: const Radius.circular(14),
//                         bottomLeft: Radius.circular(isMe ? 14 : 3),
//                         bottomRight: Radius.circular(isMe ? 3 : 14),
//                       ),
//                     ),
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       mainAxisSize: MainAxisSize.min,
//                       children: [
//                         // Quoted reply preview — WhatsApp-style snippet of
//                         // the original message above the new one.
//                         if (message.isReply)
//                           Container(
//                             margin: const EdgeInsets.only(bottom: 6),
//                             padding: const EdgeInsets.symmetric(
//                               horizontal: 8,
//                               vertical: 6,
//                             ),
//                             decoration: BoxDecoration(
//                               color:
//                                   (isMe
//                                           ? Colors.white
//                                           : _userColor(message.userId))
//                                       .withOpacity(0.15),
//                               borderRadius: BorderRadius.circular(8),
//                               border: Border(
//                                 left: BorderSide(
//                                   color: isMe
//                                       ? Colors.white70
//                                       : _userColor(message.userId),
//                                   width: 3,
//                                 ),
//                               ),
//                             ),
//                             child: Column(
//                               crossAxisAlignment: CrossAxisAlignment.start,
//                               mainAxisSize: MainAxisSize.min,
//                               children: [
//                                 Text(
//                                   message.replyToDisplayName ?? 'Someone',
//                                   style: TextStyle(
//                                     fontWeight: FontWeight.w700,
//                                     fontSize: 12,
//                                     color: isMe
//                                         ? Colors.white70
//                                         : _userColor(message.userId),
//                                   ),
//                                 ),
//                                 Text(
//                                   message.replyToContent ?? '',
//                                   maxLines: 2,
//                                   overflow: TextOverflow.ellipsis,
//                                   style: TextStyle(
//                                     fontSize: 12,
//                                     color: isMe
//                                         ? Colors.white60
//                                         : theme.colorScheme.onSurfaceVariant,
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           ),
//                         Text(
//                           message.content,
//                           style: theme.textTheme.bodyMedium?.copyWith(
//                             color: isMe
//                                 ? theme.colorScheme.onPrimary
//                                 : theme.colorScheme.onSurface,
//                             fontWeight: FontWeight.w500,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );

//     if (onSwipeReply == null) return bubble;
//     return _SwipeToReply(onReply: onSwipeReply!, child: bubble);
//   }
// }

// // ── Swipe-to-reply gesture wrapper ────────────────────────────────────────────
// // WhatsApp-style: drag any message right past a threshold to trigger a
// // reply, with a reply icon that fades in as you drag and the bubble
// // snapping back afterward.
// class _SwipeToReply extends StatefulWidget {
//   const _SwipeToReply({required this.child, required this.onReply});
//   final Widget child;
//   final VoidCallback onReply;

//   @override
//   State<_SwipeToReply> createState() => _SwipeToReplyState();
// }

// class _SwipeToReplyState extends State<_SwipeToReply> {
//   static const _triggerDrag = 56.0;
//   double _dragX = 0;
//   bool _triggered = false;

//   @override
//   Widget build(BuildContext context) {
//     return GestureDetector(
//       behavior: HitTestBehavior.translucent,
//       onHorizontalDragUpdate: (details) {
//         if (details.delta.dx < 0 && _dragX <= 0) return; // no left-swipe
//         setState(() {
//           _dragX = (_dragX + details.delta.dx).clamp(0, _triggerDrag + 16);
//           final reached = _dragX >= _triggerDrag;
//           if (reached && !_triggered) {
//             _triggered = true;
//             HapticFeedback.mediumImpact();
//           } else if (!reached) {
//             _triggered = false;
//           }
//         });
//       },
//       onHorizontalDragEnd: (_) {
//         if (_triggered) widget.onReply();
//         setState(() {
//           _dragX = 0;
//           _triggered = false;
//         });
//       },
//       child: Stack(
//         alignment: Alignment.centerLeft,
//         children: [
//           if (_dragX > 8)
//             Padding(
//               padding: const EdgeInsets.only(left: 8),
//               child: Opacity(
//                 opacity: (_dragX / _triggerDrag).clamp(0, 1),
//                 child: Icon(
//                   Icons.reply_rounded,
//                   size: 20,
//                   color: Theme.of(context).colorScheme.primary,
//                 ),
//               ),
//             ),
//           AnimatedContainer(
//             duration: _dragX == 0
//                 ? const Duration(milliseconds: 150)
//                 : Duration.zero,
//             transform: Matrix4.translationValues(_dragX, 0, 0),
//             child: widget.child,
//           ),
//         ],
//       ),
//     );
//   }
// }

// class _SendButton extends StatelessWidget {
//   const _SendButton({
//     required this.onSend,
//     required this.isSending,
//     required this.isDisabled,
//   });

//   final VoidCallback onSend;
//   final bool isSending;
//   final bool isDisabled;

//   @override
//   Widget build(BuildContext context) {
//     final active = !isSending && !isDisabled;
//     return GestureDetector(
//       onTap: active ? onSend : null,
//       child: AnimatedContainer(
//         duration: const Duration(milliseconds: 150),
//         width: 40,
//         height: 40,
//         decoration: BoxDecoration(
//           color: active
//               ? context.colorScheme.primary
//               : context.colorScheme.surfaceContainerHighest,
//           shape: BoxShape.circle,
//         ),
//         child: isSending
//             ? const Center(
//                 child: SizedBox(
//                   width: 16,
//                   height: 16,
//                   child: CircularProgressIndicator(
//                     strokeWidth: 2,
//                     color: Colors.white,
//                   ),
//                 ),
//               )
//             : Icon(
//                 Icons.send_rounded,
//                 size: 18,
//                 color: active
//                     ? Colors.white
//                     : context.colorScheme.onSurfaceVariant,
//               ),
//       ),
//     );
//   }
// }

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:jma3a/shared/widgets/cards/permium_badge.dart';
import 'package:provider/provider.dart';
import '../../../../core/extensions/context_ext.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../../../core/theme/app_colors.dart';
// import '../../../../shared/widgets/cards/premium_badge.dart';
import '../../../../shared/widgets/cards/user_avatar.dart';
import '../../domain/room_entity.dart';
import '../room_provider.dart';

const _kChatColors = [
  Color(0xFF4ECDC4),
  Color(0xFFA855F7),
  Color(0xFFFF6B6B),
  Color(0xFF4ADE80),
  Color(0xFFFB923C),
  Color(0xFF60A5FA),
  Color(0xFFF472B6),
  Color(0xFFFFD60A),
  Color(0xFF34D399),
  Color(0xFFC084FC),
];

Color _userColor(String userId) =>
    _kChatColors[userId.hashCode.abs() % _kChatColors.length];

class ChatPanel extends StatefulWidget {
  const ChatPanel({super.key, required this.room});
  final RoomProvider room;

  @override
  State<ChatPanel> createState() => _ChatPanelState();
}

class _ChatPanelState extends State<ChatPanel> {
  final _ctrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final _focusNode = FocusNode();
  bool _showScrollDown = false;
  bool _sendAnonymous = false;

  bool get _isPremium =>
      context.read<AuthProvider>().currentUser?.isPremiumActive ?? false;

  @override
  void initState() {
    super.initState();
    widget.room.addListener(_onMessages);
    _scrollCtrl.addListener(_onScroll);
  }

  @override
  void dispose() {
    widget.room.removeListener(_onMessages);
    _scrollCtrl.removeListener(_onScroll);
    _ctrl.dispose();
    _scrollCtrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onMessages() {
    if (!_showScrollDown) _scrollToBottom();
  }

  void _onScroll() {
    final atBottom =
        _scrollCtrl.position.pixels >=
        _scrollCtrl.position.maxScrollExtent - 80;
    if (atBottom != !_showScrollDown) {
      setState(() => _showScrollDown = !atBottom);
    }
  }

  void _scrollToBottom({bool animated = true}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollCtrl.hasClients) return;
      if (animated) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      } else {
        _scrollCtrl.jumpTo(_scrollCtrl.position.maxScrollExtent);
      }
    });
  }

  Future<void> _send() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    _ctrl.clear();
    await widget.room.sendChatMessage(text, anonymous: _sendAnonymous);
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final room = widget.room;
    final l10n = context.l10n;
    final theme = context.theme;
    final isMuted = room.isCurrentUserMuted;
    final chatOff = !room.settings.chatEnabled;

    return SizedBox.expand(
      child: Column(
        children: [
          if (chatOff)
            Container(
              color: theme.colorScheme.surfaceContainerHighest,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Icon(
                    Icons.voice_over_off_rounded,
                    size: 14,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Chat is disabled for this room',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),

          Expanded(
            child: Stack(
              children: [
                room.chatMessages.isEmpty
                    ? Center(
                        child: Text(
                          'No messages yet',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollCtrl,
                        padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                        itemCount: room.chatMessages.length,
                        itemBuilder: (_, i) {
                          final msg = room.chatMessages[i];
                          final isMe = msg.userId == room.currentMember?.userId;
                          return _ChatBubble(
                                message: msg,
                                isMe: isMe,
                                showAvatar:
                                    i == 0 ||
                                    room.chatMessages[i - 1].userId !=
                                        msg.userId,
                              )
                              .animate(delay: 20.ms)
                              .fadeIn()
                              .slideY(begin: 0.05, end: 0);
                        },
                      ),

                if (_showScrollDown)
                  Positioned(
                    right: 12,
                    bottom: 12,
                    child: FloatingActionButton.small(
                      heroTag: 'scroll_down',
                      onPressed: _scrollToBottom,
                      child: const Icon(Icons.keyboard_arrow_down_rounded),
                    ),
                  ),
              ],
            ),
          ),

          Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              border: Border(
                top: BorderSide(color: theme.colorScheme.outlineVariant),
              ),
            ),
            padding: EdgeInsets.fromLTRB(
              12,
              8,
              12,
              MediaQuery.viewInsetsOf(context).bottom + 8,
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _ctrl,
                    focusNode: _focusNode,
                    enabled: !isMuted && !chatOff,
                    maxLength: 500,
                    maxLines: null,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _send(),
                    decoration: InputDecoration(
                      hintText: isMuted
                          ? l10n.chatMuted
                          : chatOff
                          ? 'Chat disabled'
                          : _sendAnonymous
                          ? 'Message as Anonymous…'
                          : l10n.chatPlaceholder,
                      counterText: '',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: _sendAnonymous
                          ? Colors.purple.shade50
                          : theme.colorScheme.surfaceContainerHighest,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                    ),
                  ),
                ),
                if (_isPremium) ...[
                  const SizedBox(width: 4),
                  Tooltip(
                    message: _sendAnonymous
                        ? 'Anonymous mode on'
                        : 'Send anonymously (Premium)',
                    child: IconButton(
                      icon: Icon(
                        _sendAnonymous
                            ? Icons.person_off_rounded
                            : Icons.person_outline_rounded,
                        color: _sendAnonymous
                            ? Colors.purple
                            : theme.colorScheme.onSurfaceVariant,
                        size: 20,
                      ),
                      onPressed: () =>
                          setState(() => _sendAnonymous = !_sendAnonymous),
                    ),
                  ),
                ],
                const SizedBox(width: 4),
                _SendButton(
                  onSend: _send,
                  isSending: room.isSendingChat,
                  isDisabled: isMuted || chatOff,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({
    required this.message,
    required this.isMe,
    this.showAvatar = true,
  });

  final ChatMessageEntity message;
  final bool isMe;
  final bool showAvatar;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;

    if (message.isSystem) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              message.content,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: isMe
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: [
          if (!isMe && showAvatar) ...[
            UserAvatar(
              avatarUrl: message.avatarUrl,
              displayName: message.displayName,
              size: 26,
            ),
            const SizedBox(width: 6),
          ] else if (!isMe)
            const SizedBox(width: 32),

          Flexible(
            child: Column(
              crossAxisAlignment: isMe
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                if (!isMe && showAvatar)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 2, left: 2),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (message.isAnonymous)
                          const Padding(
                            padding: EdgeInsets.only(right: 4),
                            child: Icon(
                              Icons.person_off_rounded,
                              size: 11,
                              color: Colors.purple,
                            ),
                          ),
                        Text(
                          message.isAnonymous
                              ? 'Anonymous'
                              : message.displayName,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: message.isAnonymous
                                ? Colors.purple
                                : _userColor(message.userId),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (message.senderIsPremium &&
                            !message.isAnonymous) ...[
                          const SizedBox(width: 3),
                          PremiumBadge(
                            size: 10,
                            tier: message.senderPremiumTier,
                          ),
                        ],
                      ],
                    ),
                  ),
                Opacity(
                  opacity: message.isOptimistic ? 0.65 : 1.0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isMe
                          ? theme.colorScheme.primary
                          : message.isAnonymous
                          ? Colors.purple.withOpacity(0.12)
                          : _userColor(message.userId).withOpacity(0.18),
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(14),
                        topRight: const Radius.circular(14),
                        bottomLeft: Radius.circular(isMe ? 14 : 3),
                        bottomRight: Radius.circular(isMe ? 3 : 14),
                      ),
                    ),
                    child: Text(
                      message.content,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: isMe
                            ? theme.colorScheme.onPrimary
                            : theme.colorScheme.onSurface,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SendButton extends StatelessWidget {
  const _SendButton({
    required this.onSend,
    required this.isSending,
    required this.isDisabled,
  });

  final VoidCallback onSend;
  final bool isSending;
  final bool isDisabled;

  @override
  Widget build(BuildContext context) {
    final active = !isSending && !isDisabled;
    return GestureDetector(
      onTap: active ? onSend : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: active
              ? context.colorScheme.primary
              : context.colorScheme.surfaceContainerHighest,
          shape: BoxShape.circle,
        ),
        child: isSending
            ? const Center(
                child: SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                ),
              )
            : Icon(
                Icons.send_rounded,
                size: 18,
                color: active
                    ? Colors.white
                    : context.colorScheme.onSurfaceVariant,
              ),
      ),
    );
  }
}
