import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class NumpadWidget extends StatelessWidget {
  final double amountReceived;
  final double balanceDue;
  final NumberFormat currencyFormatter;
  final bool isCompact;
  final ValueChanged<String> onNumberPressed;
  final VoidCallback onBackspace;
  final VoidCallback onClear;
  final ValueChanged<double> onShortcutPressed;

  const NumpadWidget({
    super.key,
    required this.amountReceived,
    required this.balanceDue,
    required this.currencyFormatter,
    this.isCompact = false,
    required this.onNumberPressed,
    required this.onBackspace,
    required this.onClear,
    required this.onShortcutPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(isCompact ? 4 : 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isCompact ? 6 : 12),
        border: Border.all(color: const Color(0xFFCBD5E1), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: isCompact ? MainAxisSize.max : MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Row(
                    children: [
                      Text(
                        'Uang Diterima : ',
                        style: TextStyle(
                          fontSize: isCompact ? 11 : 14,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                      Text(
                        currencyFormatter.format(amountReceived),
                        style: TextStyle(
                          fontSize: isCompact ? 14 : 20,
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFF059669),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              TextButton(
                onPressed: onClear,
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                ),
                child: Text(
                  'Clear',
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.w900,
                    fontSize: isCompact ? 9 : 13,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: isCompact ? 2 : 6),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  flex: 4,
                  child: Column(
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Expanded(child: _numBtn('1')),
                            SizedBox(width: isCompact ? 3 : 6),
                            Expanded(child: _numBtn('2')),
                            SizedBox(width: isCompact ? 3 : 6),
                            Expanded(child: _numBtn('3')),
                          ],
                        ),
                      ),
                      SizedBox(height: isCompact ? 3 : 6),
                      Expanded(
                        child: Row(
                          children: [
                            Expanded(child: _numBtn('4')),
                            SizedBox(width: isCompact ? 3 : 6),
                            Expanded(child: _numBtn('5')),
                            SizedBox(width: isCompact ? 3 : 6),
                            Expanded(child: _numBtn('6')),
                          ],
                        ),
                      ),
                      SizedBox(height: isCompact ? 3 : 6),
                      Expanded(
                        child: Row(
                          children: [
                            Expanded(child: _numBtn('7')),
                            SizedBox(width: isCompact ? 3 : 6),
                            Expanded(child: _numBtn('8')),
                            SizedBox(width: isCompact ? 3 : 6),
                            Expanded(child: _numBtn('9')),
                          ],
                        ),
                      ),
                      SizedBox(height: isCompact ? 3 : 6),
                      Expanded(
                        child: Row(
                          children: [
                            Expanded(child: _numBtn('0')),
                            SizedBox(width: isCompact ? 3 : 6),
                            Expanded(child: _numBtn('00')),
                            SizedBox(width: isCompact ? 3 : 6),
                            Expanded(child: _numBtn('DEL')),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: isCompact ? 3 : 6),
                Expanded(
                  flex: 1,
                  child: Column(
                    children: [
                      Expanded(
                        child: _shortcutBtn('Pas', balanceDue),
                      ),
                      SizedBox(height: isCompact ? 3 : 6),
                      Expanded(
                        child: _shortcutBtn('20k', 20000),
                      ),
                      SizedBox(height: isCompact ? 3 : 6),
                      Expanded(
                        child: _shortcutBtn('50k', 50000),
                      ),
                      SizedBox(height: isCompact ? 3 : 6),
                      Expanded(
                        child: _shortcutBtn('100k', 100000),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _numBtn(String val) => InkWell(
        onTap: () => val == 'DEL' ? onBackspace() : onNumberPressed(val),
        borderRadius: BorderRadius.circular(isCompact ? 3 : 6),
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(isCompact ? 3 : 6),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: val == 'DEL'
              ? Icon(
                  Icons.backspace_rounded,
                  size: isCompact ? 12 : 18,
                  color: const Color(0xFF1E293B),
                )
              : FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    val,
                    style: TextStyle(
                      fontSize: isCompact ? 11 : 16,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFF1E293B),
                    ),
                  ),
                ),
        ),
      );

  Widget _shortcutBtn(String label, double amount) => InkWell(
        onTap: () => onShortcutPressed(amount),
        borderRadius: BorderRadius.circular(isCompact ? 3 : 6),
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: const Color(0xFFEEF2FF),
            borderRadius: BorderRadius.circular(isCompact ? 3 : 6),
            border: Border.all(color: const Color(0xFFC7D2FE)),
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              style: TextStyle(
                fontSize: isCompact ? 8 : 11,
                fontWeight: FontWeight.w900,
                color: const Color(0xFF4338CA),
              ),
            ),
          ),
        ),
      );
}
