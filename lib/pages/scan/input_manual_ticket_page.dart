import 'package:flutter/material.dart';
import 'package:kreengate/pages/scan/input_manual_ticket_dialog.dart';

/// ui/main/InputManualTicketActivity: hanya setContentView(activity_input_manual_ticket),
/// tanpa listener apa pun (EditText inputType="textEmailAddress").
class InputManualTicketPage extends StatelessWidget {
  const InputManualTicketPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const InputManualTicketView(numberInput: false, backDismisses: false);
  }
}
