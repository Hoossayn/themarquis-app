import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:marquis_v2/games/ludo/ludo_game.dart';
import 'package:marquis_v2/games/ludo/ludo_session.dart';
import 'package:marquis_v2/games/ludo/models/ludo_session.dart';
import 'package:marquis_v2/games/ludo/screens/create_game_screen.dart';
import 'package:marquis_v2/providers/app_state.dart';
import 'package:marquis_v2/providers/user.dart';
import 'package:marquis_v2/widgets/error_dialog.dart';
import 'package:marquis_v2/widgets/user_points_widget.dart';

class LudoWelcomeScreen extends ConsumerStatefulWidget {
  const LudoWelcomeScreen({super.key, required this.game});
  final LudoGame game;

  @override
  ConsumerState<LudoWelcomeScreen> createState() => _LudoWelcomeScreenState();
}

class _LudoWelcomeScreenState extends ConsumerState<LudoWelcomeScreen> {
  bool _isErrorVisible = false;
  String _errorMessage = "";

  void _showError(String error) {
    _errorMessage = error;
    setState(() {
      _isErrorVisible = true;
    });
    Future.delayed(const Duration(seconds: 3), _dismissError);
  }

  void _dismissError() {
    if (!_isErrorVisible) return;
    setState(() {
      _errorMessage = "";
      _isErrorVisible = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
    // final deviceSize = MediaQuery.of(context).size;
    final user = ref.read(userProvider);
    // final ludoSession = ref.read(ludoSessionProvider.notifier);
    if (user == null) {
      return const Center(child: Text("Not Logged In"));
    }
    return Stack(
      alignment: Alignment.center,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            double scaledHeight(double height) {
              return (height / 717) * constraints.maxHeight;
            }

            return Column(
              children: [
                const UserPointsWidget(),
                SizedBox(height: scaledHeight(8)),
                Flexible(
                  child: Container(
                    width: double.infinity,
                    height: scaledHeight(290),
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: const AssetImage('assets/images/ludo.png'),
                        colorFilter: ColorFilter.mode(Colors.black.withOpacity(0.5), BlendMode.darken),
                        fit: BoxFit.cover,
                      ),
                    ),
                    padding: const EdgeInsets.all(16.0),
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'LUDO',
                          style: TextStyle(
                            fontSize: 40,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            shadows: [Shadow(blurRadius: 10.6, color: Color(0xFF00ECFF), offset: Offset(0, 0))],
                          ),
                        ),
                        Text('MENU', style: TextStyle(fontSize: 15, color: Colors.white, letterSpacing: 8)),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(left: 69, right: 35, top: scaledHeight(25), bottom: scaledHeight(25)),
                  child: Column(
                    children: [
                      if (user.sessionId != null) ...[
                        SizedBox(
                          height: scaledHeight(64),
                          child: FittedBox(
                            child: MenuButton(
                                icon: Icons.play_arrow,
                                label: 'Resume Game',
                                onTap: () async {
                                  try {
                                    ref.read(appStateProvider.notifier).selectGameSessionId("ludo", user.sessionId);
                                    var session = ref.read(ludoSessionProvider);
                                    if (session == null) {
                                      await ref.read(ludoSessionProvider.notifier).getLudoSession();
                                      session = ref.read(ludoSessionProvider);
                                    }
                                    if (session == null) return;
                                    if (session.sessionUserStatus.where((e) => e.status == "ACTIVE").length == 4) {
                                      widget.game.playState = PlayState.playing;
                                    } else {
                                      widget.game.playState = PlayState.waiting;
                                    }
                                  } catch (e) {
                                    if (!context.mounted) return;
                                    showErrorDialog(e.toString(), context);
                                  }
                                }),
                          ),
                        ),
                        SizedBox(height: scaledHeight(20)),
                      ],
                      if (user.sessionId != null) ...[
                        SizedBox(
                          height: scaledHeight(64),
                          child: FittedBox(
                            child: MenuButton(
                                icon: Icons.exit_to_app,
                                label: 'Exit Game',
                                onTap: () async {
                                  try {
                                    // Show confirmation dialog
                                    final bool confirmExit = await showDialog(
                                      context: context,
                                      builder: (BuildContext context) {
                                        return AlertDialog(
                                          title: const Text('Exit Game'),
                                          content: const Text('Are you sure you want to exit the current game?'),
                                          actions: <Widget>[
                                            TextButton(
                                              child: const Text('Cancel'),
                                              onPressed: () {
                                                Navigator.of(context).pop(false);
                                              },
                                            ),
                                            TextButton(
                                              child: const Text('Exit'),
                                              onPressed: () {
                                                Navigator.of(context).pop(true);
                                              },
                                            ),
                                          ],
                                        );
                                      },
                                    );

                                    // If user doesn't confirm, return early
                                    if (!confirmExit) return;
                                    await ref.read(ludoSessionProvider.notifier).exitSession();
                                    setState(() {});
                                  } catch (e) {
                                    if (!context.mounted) return;
                                    showErrorDialog(e.toString(), context);
                                  }
                                }),
                          ),
                        ),
                        SizedBox(height: scaledHeight(20)),
                      ],
                      if (user.sessionId == null) ...[
                        SizedBox(
                          height: scaledHeight(64),
                          child: FittedBox(
                            child: MenuButton(icon: Icons.add, label: 'Create Game', onTap: () => createRoomDialog(ctx: context, game: widget.game)),
                          ),
                        ),
                        SizedBox(height: scaledHeight(20)),
                      ],
                      if (user.sessionId == null) ...[
                        SizedBox(
                          height: scaledHeight(64),
                          child: FittedBox(
                            child: MenuButton(icon: Icons.group, label: 'Find Game', onTap: () => findRoomDialog(ctx: context, game: widget.game)),
                          ),
                        ),
                        SizedBox(height: scaledHeight(20)),
                      ],
                      if (user.sessionId == null) ...[
                        SizedBox(
                          height: scaledHeight(64),
                          child: FittedBox(
                            child: MenuButton(icon: Icons.casino, label: 'Join Game', onTap: () => joinGameDialog(ctx: context, game: widget.game)),
                          ),
                        ),
                        SizedBox(height: scaledHeight(20)),
                      ],
                      SizedBox(
                        height: scaledHeight(64),
                        child: FittedBox(child: MenuButton(icon: Icons.home, label: 'Back to Home', onTap: Navigator.of(context).pop)),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
        if (_isErrorVisible)
          Positioned(
            top: 23,
            child: Container(
              constraints: const BoxConstraints(maxWidth: 244),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF4F2934), Color(0xFF843C4C), Color(0xFF0F0E13)]),
                boxShadow: const [BoxShadow(color: Color(0x40000000), blurRadius: 24, offset: Offset(0, 16))],
                border: Border.all(color: const Color(0xFF40474D)),
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SvgPicture.asset("assets/svg/error_icon.svg"),
                  Flexible(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text(_errorMessage, maxLines: 4, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14)),
                    ),
                  ),
                  GestureDetector(onTap: _dismissError, child: const Icon(Icons.close, size: 24, color: Colors.white)),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Future joinGameDialog({required BuildContext ctx, required LudoGame game}) {
    return showDialog(
      context: ctx,
      builder: (BuildContext context) {
        return JoinGameDialog(game: widget.game, errorHandler: _showError);
      },
    );
  }

  Future findRoomDialog({required BuildContext ctx, required LudoGame game}) {
    return showDialog(
      context: ctx,
      builder: (BuildContext context) {
        return FindRoomDialog(game: game, errorHandler: _showError);
      },
    );
  }

  createRoomDialog({required BuildContext ctx, required LudoGame game}) {
    Navigator.of(context).push(MaterialPageRoute(builder: (context) => const CreateGameScreen(), settings: RouteSettings(arguments: game)));
    // return showDialog(
    //   context: ctx,
    //   builder: (BuildContext context) {
    //     return CreateRoomDialog(game: game);
    //   },
    // );
  }
}

class MenuButton extends StatelessWidget {
  final String _label;
  final VoidCallback _onTap;
  final IconData _icon;
  const MenuButton({required String label, required IconData icon, required VoidCallback onTap, super.key})
      : _label = label,
        _onTap = onTap,
        _icon = icon;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: _onTap,
      child: Stack(
        clipBehavior: Clip.none, // Allow children to be drawn outside the stack
        alignment: Alignment.center,
        children: [
          Container(
            width: 268,
            height: 53,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              gradient: const LinearGradient(colors: [Color(0xFF0E272F), Color(0xFF0F1118)], stops: [0.6, 1]),
            ),
            padding: const EdgeInsets.only(left: 55),
            alignment: Alignment.centerLeft,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_label, style: const TextStyle(color: Colors.white, fontSize: 10)),
                Container(color: const Color(0xFF00ECFF), height: 2, width: 28),
              ],
            ),
          ),
          Positioned(
            left: -34, // Adjust this value to control how much it extends out
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFF00ECff), width: 3),
                shape: BoxShape.circle,
                color: const Color(0xFF0E272F),
              ),
              child: Icon(_icon, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}

class FindRoomDialog extends ConsumerStatefulWidget {
  const FindRoomDialog({super.key, required this.game, this.roomId, required this.errorHandler});

  final LudoGame game;
  final String? roomId;
  final void Function(String) errorHandler;

  @override
  ConsumerState<FindRoomDialog> createState() => _FindRoomDialogState();
}

class _FindRoomDialogState extends ConsumerState<FindRoomDialog> {
  final _roomIdController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _roomIdController.text = widget.roomId ?? "";
  }

  Future<void> searchRoom() async {
    setState(() {
      _isLoading = true;
    });
    try {
      FocusScope.of(context).unfocus();
      final ludoSession = await getLudoSessionFromId(_roomIdController.text);
      if (ludoSession == null) {
        if (!mounted) return;
        showErrorDialog("Room not found", context);
        return;
      }
      if (!mounted) return;
      final res = await showDialog(
          context: context,
          builder: (c) {
            return FindGameChooseColorDialog(roomId: _roomIdController.text, selectedSession: ludoSession, game: widget.game);
          });
      if (res == true) {
        if (!mounted) return;
        Navigator.of(context).pop(true);
        widget.game.playState = PlayState.waiting;
      }
    } catch (e) {
      if (!mounted) return;
      if (e is HttpException) {
        widget.errorHandler(e.message);
        return;
      }
      widget.errorHandler(e.toString());
      showErrorDialog(e.toString(), context);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(textTheme: GoogleFonts.montserratTextTheme()),
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        clipBehavior: Clip.antiAlias,
        backgroundColor: const Color(0xFF21262B),
        child: SizedBox(
          width: MediaQuery.of(context).size.width * 0.80,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text(
                  'Find Game',
                  style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 16),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Room ID",
                    style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w500),
                  ),
                ),
                SizedBox(
                  height: 41,
                  child: TextField(
                    style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w400),
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                      hintText: "Please enter room ID",
                      hintStyle: const TextStyle(color: Color(0xFF8B8B8B), fontSize: 14, fontWeight: FontWeight.w400),
                      fillColor: const Color(0xFF363D43),
                      filled: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(4),
                        borderSide: const BorderSide(color: Colors.transparent),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(4),
                        borderSide: const BorderSide(color: Colors.transparent),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(4),
                        borderSide: const BorderSide(color: Colors.transparent),
                      ),
                    ),
                    controller: _roomIdController,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: Navigator.of(context).pop,
                        style: OutlinedButton.styleFrom(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            foregroundColor: const Color(0xFF00ECFF),
                            side: const BorderSide(color: Color(0xFF00ECFF))),
                        child: const Text("Cancel"),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: searchRoom,
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          foregroundColor: Colors.black,
                          backgroundColor: const Color(0xFF00ECFF),
                        ),
                        child: _isLoading ? const CircularProgressIndicator() : const Text("Confirm"),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class JoinGameDialog extends ConsumerStatefulWidget {
  const JoinGameDialog({super.key, required this.game, required this.errorHandler});

  final LudoGame game;
  final void Function(String) errorHandler;

  @override
  ConsumerState<JoinGameDialog> createState() => _JoinGameDialogState();
}

class _JoinGameDialogState extends ConsumerState<JoinGameDialog> {
  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(textTheme: GoogleFonts.montserratTextTheme()),
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: const Color(0xFF21262B),
        clipBehavior: Clip.antiAlias,
        child: FutureBuilder<List<LudoSessionData>>(future: () async {
          final rooms = await ref.read(ludoSessionProvider.notifier).getOpenSessions();
          return rooms;
        }(), builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SizedBox(
              width: 100,
              height: 100,
              child: Center(child: CircularProgressIndicator()),
            );
          }
          if (snapshot.hasError) {
            return Text(snapshot.error.toString());
          }
          return SizedBox(
            width: MediaQuery.of(context).size.width * 0.80,
            height: MediaQuery.of(context).size.height * 0.70,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Align(
                    alignment: Alignment.centerRight,
                    child: IconButton(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.all(0),
                      onPressed: Navigator.of(context).pop,
                      icon: const Icon(Icons.cancel_outlined, color: Colors.white, size: 22),
                    ),
                  ),
                  const Text('Join Game', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 16),
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Column(
                        children: [
                          ...snapshot.data!.map(
                            (sessionData) =>
                                OpenSessionRoomCard(game: widget.game, sessionData: sessionData, context: context, errorHandler: widget.errorHandler),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

class OpenSessionRoomCard extends StatelessWidget {
  const OpenSessionRoomCard({super.key, required this.game, required this.sessionData, required this.context, required this.errorHandler});

  final LudoGame game;
  final LudoSessionData sessionData;
  final BuildContext context;
  final void Function(String) errorHandler;

  @override
  Widget build(BuildContext context) {
    final colors = sessionData.getListOfColors;
    final roomName = sessionData.id;
    final noOfPlayers = sessionData.sessionUserStatus.map((e) => e.status == "ACTIVE" ? 1 : 0).reduce((value, element) => value + element);
    final roomColor = sessionData.playAmount == '0'
        ? const Color(0xFF00ECFF)
        : sessionData.playToken == "STRK"
            ? const Color(0xFF0077FF)
            : sessionData.playToken == "ETH"
                ? const Color(0xFF7531F4)
                : const Color(0xFF404040);
    final roomStake = sessionData.playAmount == '0' ? "Free" : "${sessionData.playAmount} ${sessionData.playToken}";
    return Theme(
      data: Theme.of(context).copyWith(textTheme: GoogleFonts.orbitronTextTheme()),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(color: const Color(0x94181B25), border: Border.all(color: const Color(0xFF2E2E2E)), borderRadius: BorderRadius.circular(4)),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text("ROOM $roomName", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.white)),
                    const SizedBox(width: 4),
                    Container(
                      decoration: BoxDecoration(border: Border.all(color: roomColor), borderRadius: BorderRadius.circular(30)),
                      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                      child: Text(roomStake, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.white)),
                    ),
                  ],
                ),
                Text("$noOfPlayers/4 Players", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF979797))),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                //four avatar
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    for (int i = 0; i < noOfPlayers; i++) PlayerAvatarCard(index: i, size: 37, color: colors[i]),
                    for (int i = 0; i < 4 - noOfPlayers; i++) const PlayerEmptyCard(size: 37),
                  ],
                ),
                //join button
                noOfPlayers == 4
                    ? const SizedBox(
                        child: Text("FULL"),
                      )
                    : TextButton(
                        onPressed: () async {
                          final res = await showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return FindRoomDialog(game: game, roomId: roomName, errorHandler: errorHandler);
                            },
                          );
                          if (res == true) {
                            if (!context.mounted) return;
                            Navigator.of(context).pop();
                          }
                        },
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero, // Remove the default padding from TextButton
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color.fromARGB(255, 0, 236, 255), // Background color
                            borderRadius: BorderRadius.circular(8), // Rounded edges
                          ),
                          padding: const EdgeInsets.symmetric(
                            vertical: 10.0,
                            horizontal: 25.0,
                          ), // Padding inside the button
                          child: const Text(
                            "JOIN",
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.black, // Text color
                            ),
                          ),
                        ),
                      ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class PlayerEmptyCard extends StatelessWidget {
  const PlayerEmptyCard({
    super.key,
    required this.size,
  });

  final double size;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: Container(
        width: size, // Width of the displayed sprite
        height: size, // Height of the displayed sprite
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(size / 8),
          border: Border.all(
            color: Colors.white,
            width: 1.5,
          ),
        ),
        child: Center(child: SvgPicture.asset("assets/svg/empty_player_avatar.svg")),
      ),
    );
  }
}

class PlayerAvatarCard extends StatelessWidget {
  const PlayerAvatarCard({super.key, required this.index, required this.size, required this.color});

  final int index;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: Container(
        width: size, // Width of the displayed sprite
        height: size, // Height of the displayed sprite
        decoration: BoxDecoration(
          color: color, // Background color
          borderRadius: BorderRadius.circular(size / 8), // Rounded corners with radius 24
        ),
        child: FittedBox(
          fit: BoxFit.fill,
          child: ClipRect(
            child: Align(
              alignment: index == 1
                  ? Alignment.topLeft
                  : index == 2
                      ? Alignment.topRight
                      : index == 3
                          ? Alignment.bottomLeft
                          : Alignment.bottomRight,
              // widthFactor: 2160 / 4324,
              // heightFactor: 2160 / 4324,
              widthFactor: 0.5,
              heightFactor: 0.5,
              child: Image.asset(
                'assets/images/avatar_spritesheet.png', // Path to your spritesheet
                width: 4324, // Full width of the sprite sheet
                height: 4324, // Full height of the sprite sheet
                fit: BoxFit.none, // Ensure no scaling occurs
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class CreateRoomDialog extends ConsumerStatefulWidget {
  const CreateRoomDialog({super.key, required this.game});

  final LudoGame game;

  @override
  ConsumerState<CreateRoomDialog> createState() => _CreateRoomDialogState();
}

class _CreateRoomDialogState extends ConsumerState<CreateRoomDialog> {
  BigInt _sliderValue = BigInt.from(0);
  BigInt? _tokenBalance;
  String _selectedTokenAddress = '';
  final _tokenAmountController = TextEditingController();
  List<Map<String, String>>? _supportedTokens;
  String? _selectedColor; // To keep track of the selected color
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: FutureBuilder(
          future: _supportedTokens == null
              ? () async {
                  _supportedTokens = await ref.read(userProvider.notifier).getSupportedTokens();
                }()
              : null,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox(
                width: 100,
                height: 100,
                child: Center(child: CircularProgressIndicator()),
              );
            }
            if (snapshot.hasError) {
              return Text(snapshot.error.toString());
            }
            return Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: const Color.fromARGB(255, 0, 236, 255), // Cyan border color
                  width: 1, // Border thickness
                ),
                borderRadius: BorderRadius.circular(12), // Ensure the border follows the shape of the dialog
              ),
              child: SizedBox(
                width: MediaQuery.of(context).size.width * 0.80,
                height: MediaQuery.of(context).size.height * 0.50 < 450 ? 450 : MediaQuery.of(context).size.height * 0.50,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        mainAxisSize: MainAxisSize.max,
                        children: [
                          const Expanded(
                            flex: 1,
                            child: SizedBox(),
                          ),
                          const Expanded(
                            flex: 3,
                            child: Center(
                              child: Text(
                                'CREATE ROOM',
                                style: TextStyle(
                                  color: Color.fromARGB(255, 0, 236, 255), // Cyan border color
                                  fontSize: 18,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 1,
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: IconButton(
                                visualDensity: VisualDensity.compact,
                                padding: const EdgeInsets.all(0),
                                onPressed: Navigator.of(context).pop,
                                icon: const Icon(Icons.cancel_outlined, color: Colors.white, size: 22),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 22),
                      const Text(
                        "Please Select Your Color",
                        style: TextStyle(
                          color: Color.fromARGB(
                            255,
                            0,
                            236,
                            255,
                          ), // Cyan border color
                          fontSize: 12, fontWeight: FontWeight.w400,
                        ),
                      ),
                      const SizedBox(
                        height: 14,
                      ),
                      StatefulBuilder(
                        builder: (ctx, stste) {
                          return Column(
                            children: [
                              ColorChoosingCard(
                                onColorPicked: (color) {
                                  setState(() {
                                    _selectedColor = color;
                                  });
                                },
                              ),
                              const SizedBox(
                                height: 14,
                              ),
                              Row(
                                children: [
                                  Expanded(
                                    flex: 2,
                                    child: DropdownButtonFormField<String>(
                                      isExpanded: true,
                                      decoration: const InputDecoration(
                                        labelText: 'Token',
                                      ),
                                      items: [
                                        ...?_supportedTokens,
                                        {
                                          "tokenAddress": "0x0000000000000000000000000000000000000000000000000000000000000000",
                                          "tokenName": "No Token",
                                        },
                                      ].map((Map<String, String> value) {
                                        return DropdownMenuItem<String>(
                                          value: value['tokenAddress']!,
                                          child: Text(value['tokenName']!),
                                        );
                                      }).toList(),
                                      onChanged: (String? newValue) {
                                        stste(() {
                                          _selectedTokenAddress = newValue!;
                                          _tokenBalance = null;
                                        });
                                      },
                                    ),
                                  ),
                                  if (_selectedTokenAddress != "0x0000000000000000000000000000000000000000000000000000000000000000") const SizedBox(width: 16),
                                  if (_selectedTokenAddress != "0x0000000000000000000000000000000000000000000000000000000000000000")
                                    Expanded(
                                      flex: 3,
                                      child: TextField(
                                        decoration: const InputDecoration(
                                          labelText: 'Token Amount',
                                        ),
                                        controller: _tokenAmountController,
                                        keyboardType: TextInputType.number,
                                        inputFormatters: [
                                          FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*$')),
                                          TextInputFormatter.withFunction((oldValue, newValue) {
                                            if (newValue.text.isEmpty) {
                                              return newValue;
                                            }
                                            double? value = double.tryParse(newValue.text);
                                            if (value != null && _tokenBalance != null && value <= _tokenBalance!.toDouble() / 1e18) {
                                              return newValue;
                                            }
                                            return oldValue;
                                          }),
                                        ],
                                        onChanged: (value) {
                                          if (value.isNotEmpty) {
                                            stste(() {
                                              _sliderValue = BigInt.from(double.parse(value) * 1e18);
                                            });
                                          }
                                        },
                                      ),
                                    ),
                                ],
                              ),
                              if (_selectedTokenAddress != "0x0000000000000000000000000000000000000000000000000000000000000000" && _selectedTokenAddress != "")
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: FutureBuilder(
                                    future: _tokenBalance != null
                                        ? null
                                        : () async {
                                            if (_selectedTokenAddress == "0x0000000000000000000000000000000000000000000000000000000000000000") {
                                              _sliderValue = BigInt.from(0);
                                              _tokenBalance = BigInt.from(0);
                                              return;
                                            }
                                            final res = await ref.read(userProvider.notifier).getTokenBalance(_selectedTokenAddress);
                                            _sliderValue = BigInt.from(0);
                                            _tokenBalance = res;
                                          }(),
                                    builder: (context, snapshot) {
                                      if (snapshot.connectionState == ConnectionState.waiting) {
                                        return const CircularProgressIndicator();
                                      }
                                      if (snapshot.hasError) {
                                        return Text(snapshot.error.toString());
                                      }
                                      return Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Select amount:',
                                            style: TextStyle(color: Colors.white),
                                          ),
                                          Slider(
                                            min: 0.0,
                                            max: _tokenBalance!.toDouble(), // Convert int to double
                                            divisions: 100,
                                            label: (_sliderValue.toDouble() / 1e18)
                                                .toStringAsFixed(8)
                                                .replaceAll(RegExp(r'0+$'), '')
                                                .replaceAll(RegExp(r'\.$'), ''),
                                            value: _sliderValue.toDouble(),
                                            onChanged: (double value) {
                                              stste(() {
                                                _sliderValue = BigInt.from(value);
                                                _tokenAmountController.text = (_sliderValue.toDouble() / 1e18)
                                                    .toStringAsFixed(8)
                                                    .replaceAll(RegExp(r'0+$'), '')
                                                    .replaceAll(RegExp(r'\.$'), '');
                                              });
                                            },
                                          ),
                                          Text(
                                            'Max: ${(_tokenBalance!.toDouble() / 1e18).toStringAsFixed(8).replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '')}',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      );
                                    },
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(
                        height: 8,
                      ),
                      _isLoading
                          ? const CircularProgressIndicator()
                          : Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: TextButton(
                                onPressed: () async {
                                  print(
                                      "${(_sliderValue.toDouble() / 1e18).toStringAsFixed(8).replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '')}   ${_tokenAmountController.text}   $_selectedTokenAddress");
                                  try {
                                    if (_selectedColor == null) {
                                      showErrorDialog("Please select a color", context);
                                      return;
                                    }
                                    if (_selectedTokenAddress == "") {
                                      showErrorDialog("Please select a token", context);
                                      return;
                                    }
                                    setState(() {
                                      _isLoading = true;
                                    });
                                    await ref.read(ludoSessionProvider.notifier).createSession(
                                          _sliderValue.toString(),
                                          _selectedColor!,
                                          _selectedTokenAddress,
                                        );
                                  } catch (e) {
                                    if (!context.mounted) return;
                                    showErrorDialog(e.toString(), context);
                                  }
                                  setState(() {
                                    _isLoading = false;
                                  });

                                  if (!context.mounted) return;
                                  Navigator.of(context).pop();

                                  widget.game.playState = PlayState.waiting;
                                },
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                ),
                                child: Container(
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: const Color.fromARGB(255, 0, 236, 255),
                                      width: 1.2,
                                    ),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 8.0,
                                    horizontal: 42.0,
                                  ),
                                  child: const Text(
                                    "Create",
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                    ],
                  ),
                ),
              ),
            );
          }),
    );
  }
}

class ColorChoosingCard extends StatefulWidget {
  const ColorChoosingCard({super.key, required this.onColorPicked, this.takenColors = const []});
  final Function(String) onColorPicked;
  final List<String> takenColors;

  @override
  State<ColorChoosingCard> createState() => _ColorChoosingCardState();
}

class _ColorChoosingCardState extends State<ColorChoosingCard> {
  final colors = ["red", "blue", "green", "yellow"];
  late final List<String> _takenColors;
  int _pickedColorIndex = 0;

  @override
  void initState() {
    _takenColors = widget.takenColors;
    print("Taken Colors: $_takenColors");
    _pickedColorIndex = colors.indexWhere((color) => !_takenColors.contains(color));
    Future.delayed(Duration.zero, () => widget.onColorPicked(colors[_pickedColorIndex]));
    super.initState();
  }

  String _getColorBackground(int index) {
    switch (index) {
      case 0:
        return "red_bg";
      case 1:
        return "blue_bg";

      case 2:
        return "green_bg";
      case 3:
        return "yellow_bg";
      default:
        return "blue_bg";
    }
  }

  String _getColorChess(int index) {
    switch (index) {
      case 0:
        return "red_chess";

      case 1:
        return "blue_chess";

      case 2:
        return "green_chess";
      case 3:
        return "yellow_chess";
      default:
        return "blue_chess";
    }
  }

  Widget _buildCornerBorder({double? top, double? left, double? right, double? bottom}) {
    return Positioned(
      top: top,
      left: left,
      right: right,
      bottom: bottom,
      child: Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(
          border: Border(
            top: top != null ? const BorderSide(width: 2, color: Colors.white) : BorderSide.none,
            left: left != null ? const BorderSide(width: 2, color: Colors.white) : BorderSide.none,
            right: right != null ? const BorderSide(width: 2, color: Colors.white) : BorderSide.none,
            bottom: bottom != null ? const BorderSide(width: 2, color: Colors.white) : BorderSide.none,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ...colors.map(
          (color) => GestureDetector(
            onTap: () {
              if (_takenColors.contains(color)) {
                return;
              }
              setState(() {
                _pickedColorIndex = colors.indexOf(color);
                widget.onColorPicked(color);
              });
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Opacity(
                opacity: _pickedColorIndex == colors.indexOf(color) ? 1 : 0.6,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 52,
                      height: 52,
                      child: SvgPicture.asset(
                        "assets/svg/chess-and-bg/${_getColorBackground(colors.indexOf(color))}.svg",
                      ),
                    ),
                    SizedBox(
                      width: 30,
                      height: 30,
                      child: SvgPicture.asset(
                        "assets/svg/chess-and-bg/${_getColorChess(colors.indexOf(color))}.svg",
                      ),
                    ),
                    if (_pickedColorIndex == colors.indexOf(color)) _buildCornerBorder(top: 0, left: 0),
                    if (_pickedColorIndex == colors.indexOf(color)) _buildCornerBorder(top: 0, right: 0),
                    if (_pickedColorIndex == colors.indexOf(color)) _buildCornerBorder(bottom: 0, left: 0),
                    if (_pickedColorIndex == colors.indexOf(color)) _buildCornerBorder(bottom: 0, right: 0),
                    if (_takenColors.contains(color))
                      SizedBox(
                        width: 52,
                        height: 52,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(200),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class FindGameChooseColorDialog extends ConsumerStatefulWidget {
  const FindGameChooseColorDialog({super.key, required this.roomId, required this.selectedSession, required this.game});
  final String roomId;
  final LudoSessionData selectedSession;
  final LudoGame game;

  @override
  ConsumerState<FindGameChooseColorDialog> createState() => _FindGameChooseColorDialogState();
}

class _FindGameChooseColorDialogState extends ConsumerState<FindGameChooseColorDialog> {
  final String _selectedColor = "";
  bool isLoading = false;
  // BigInt? _tokenBalance;
  // final BigInt _sliderValue = BigInt.from(0);
  // List<Map<String, String>>? _supportedTokens;

  late final colors = widget.selectedSession.getListOfColors;
  late final roomName = widget.selectedSession.id;
  late final noOfPlayers = widget.selectedSession.sessionUserStatus.map((e) => e.status == "ACTIVE" ? 1 : 0).reduce((value, element) => value + element);
  late final roomColor = widget.selectedSession.playAmount == '0'
      ? const Color(0xFF00ECFF)
      : widget.selectedSession.playToken == "STRK"
          ? const Color(0xFF0077FF)
          : widget.selectedSession.playToken == "ETH"
              ? const Color(0xFF7531F4)
              : const Color(0xFF404040);
  late final roomStake = widget.selectedSession.playAmount == '0' ? "Free" : "${widget.selectedSession.playAmount} ${widget.selectedSession.playToken}";

  Future<void> joinGame() async {
    try {
      setState(() {
        isLoading = true;
      });
      if (_selectedColor == "") {
        showErrorDialog("Please select a color", context);
        return;
      }
      await ref.read(ludoSessionProvider.notifier).joinSession(widget.roomId, _selectedColor);
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      showErrorDialog(e.toString(), context);
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: const Color(0xFF21262B),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: IconButton(onPressed: Navigator.of(context).pop, icon: const Icon(Icons.cancel_outlined, color: Colors.white)),
            ),
            const Text('Room Found!', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              decoration: BoxDecoration(
                color: const Color(0x94181B25),
                border: Border.all(color: const Color(0xFF2E2E2E)),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text("ROOM $roomName", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.white)),
                          const SizedBox(width: 4),
                          Container(
                            decoration: BoxDecoration(border: Border.all(color: roomColor), borderRadius: BorderRadius.circular(30)),
                            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                            child: Text(roomStake, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.white)),
                          ),
                        ],
                      ),
                      Text("$noOfPlayers/4 Players", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF979797))),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (int i = 0; i < noOfPlayers; i++) PlayerAvatarCard(index: i, size: 55, color: colors[i]),
                      for (int i = 0; i < 4 - noOfPlayers; i++) const PlayerEmptyCard(size: 55),
                    ],
                  )
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: Navigator.of(context).pop,
                      style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          foregroundColor: const Color(0xFF00ECFF),
                          side: const BorderSide(color: Color(0xFF00ECFF))),
                      child: const Text("Back"),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: noOfPlayers == 4 ? null : joinGame,
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        foregroundColor: Colors.black,
                        backgroundColor: const Color(0xFF00ECFF),
                        disabledBackgroundColor: const Color(0xFF00ECFF).withOpacity(0.5),
                      ),
                      child: const Text("Join"),
                    ),
                  ),
                ],
              ),
            ),
            // Padding(
            //   padding: const EdgeInsets.all(8.0),
            //   child: ColorChoosingCard(
            //     onColorPicked: (color) {
            //       setState(() {
            //         _selectedColor = color;
            //       });
            //     },
            //     takenColors: widget.selectedSession.notAvailableColors,
            //   ),
            // ),
            // Padding(
            //   padding: const EdgeInsets.all(8.0),
            //   child: FutureBuilder(
            //       future: _supportedTokens == null
            //           ? () async {
            //               _supportedTokens = await ref.read(userProvider.notifier).getSupportedTokens();
            //               _supportedTokens!.add({
            //                 "tokenAddress": "0x0000000000000000000000000000000000000000000000000000000000000000",
            //                 "tokenName": "No Token",
            //               });
            //             }()
            //           : null,
            //       builder: (context, snapshot) {
            //         if (snapshot.connectionState == ConnectionState.waiting) {
            //           return const CircularProgressIndicator();
            //         }
            //         return Container(
            //           decoration: BoxDecoration(
            //             border: Border.all(color: Colors.grey, width: 1.2),
            //             borderRadius: BorderRadius.circular(6),
            //           ),
            //           padding: const EdgeInsets.symmetric(horizontal: 16.0),
            //           child: Row(
            //             mainAxisAlignment: MainAxisAlignment.center,
            //             children: [
            //               Padding(
            //                 padding: const EdgeInsets.all(8.0),
            //                 child: Text(
            //                   _supportedTokens?.firstWhere((e) => e["tokenAddress"] == widget.selectedSession.playToken)["tokenName"] ?? "",
            //                   style: const TextStyle(
            //                     color: Colors.white,
            //                     fontSize: 16,
            //                     fontWeight: FontWeight.w500,
            //                   ),
            //                 ),
            //               ),
            //               if (widget.selectedSession.playToken != "0x0000000000000000000000000000000000000000000000000000000000000000")
            //                 Padding(
            //                   padding: const EdgeInsets.all(8.0),
            //                   child: Text(
            //                     (double.parse(widget.selectedSession.playAmount) / 1e18)
            //                         .toStringAsFixed(8)
            //                         .replaceAll(RegExp(r'0+$'), '')
            //                         .replaceAll(RegExp(r'\.$'), ''),
            //                     style: const TextStyle(
            //                       color: Colors.white,
            //                       fontSize: 18,
            //                       fontWeight: FontWeight.bold,
            //                     ),
            //                   ),
            //                 ),
            //             ],
            //           ),
            //         );
            //       }),
            // ),
            // if (widget.selectedSession.playToken != "0x0000000000000000000000000000000000000000000000000000000000000000")
            //   Padding(
            //     padding: const EdgeInsets.all(8.0),
            //     child: FutureBuilder(
            //       future: _tokenBalance != null
            //           ? null
            //           : () async {
            //               final res = await ref.read(userProvider.notifier).getTokenBalance(widget.selectedSession.playToken);
            //               _sliderValue = BigInt.parse(widget.selectedSession.playAmount);
            //               _tokenBalance = res;
            //             }(),
            //       builder: (context, snapshot) {
            //         if (snapshot.connectionState == ConnectionState.waiting) {
            //           return const CircularProgressIndicator();
            //         }
            //         if (snapshot.hasError) {
            //           return Text(snapshot.error.toString());
            //         }
            //         return Column(
            //           crossAxisAlignment: CrossAxisAlignment.start,
            //           children: [
            //             Slider(
            //               min: 0.0,
            //               max: _tokenBalance!.toDouble(), // Convert int to double
            //               divisions: 100,
            //               label: (_sliderValue.toDouble() / 1e18).toStringAsFixed(8).replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), ''),
            //               value: _sliderValue.toDouble(),
            //               onChanged: (_) {},
            //             ),
            //             Text(
            //               'Max: ${(_tokenBalance!.toDouble() / 1e18).toStringAsFixed(8).replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '')}',
            //               style: const TextStyle(
            //                 color: Colors.white,
            //                 fontSize: 12,
            //               ),
            //             ),
            //           ],
            //         );
            //       },
            //     ),
            //   ),
            // _isLoading
            //     ? const CircularProgressIndicator()
            //     : Padding(
            //         padding: const EdgeInsets.all(8.0),
            //         child: TextButton(
            //           onPressed: () async {
            //             try {
            //               setState(() {
            //                 _isLoading = true;
            //               });
            //               if (_selectedColor == "") {
            //                 showErrorDialog("Please select a color", context);
            //                 return;
            //               }
            //               await ref.read(ludoSessionProvider.notifier).joinSession(
            //                     widget.roomId,
            //                     _selectedColor,
            //                   );
            //               if (!context.mounted) return;
            //               Navigator.of(context).pop(true);
            //             } catch (e) {
            //               if (!context.mounted) return;
            //               showErrorDialog(e.toString(), context);
            //             }
            //             setState(() {
            //               _isLoading = false;
            //             });
            //           },
            //           style: TextButton.styleFrom(
            //             padding: EdgeInsets.zero,
            //             // Remove the default splash effect
            //             splashFactory: NoSplash.splashFactory,
            //           ),
            //           child: Container(
            //             decoration: BoxDecoration(
            //               border: Border.all(
            //                 color: const Color.fromARGB(255, 0, 236, 255),
            //                 width: 1.2,
            //               ),
            //               borderRadius: BorderRadius.circular(6),
            //               // boxShadow: [
            //               //   BoxShadow(
            //               //     color: Colors.pink,
            //               //     spreadRadius: -4,
            //               //     blurRadius: 10,
            //               //   ),
            //               // ],
            //             ),
            //             padding: const EdgeInsets.symmetric(
            //               vertical: 8.0,
            //               horizontal: 42.0,
            //             ),
            //             child: const Text(
            //               "Join Session",
            //               style: TextStyle(
            //                 fontSize: 14,
            //                 color: Colors.white,
            //               ),
            //             ),
            //           ),
            //         ),
            //       ),
          ],
        ),
      ),
    );
  }
}
