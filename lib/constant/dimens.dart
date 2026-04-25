import 'package:flutter/material.dart';

const double multiplier = 0.94;

const Radius cornerRadiusXS = Radius.circular(4.0 * multiplier);
const Radius cornerRadiusSM = Radius.circular(8.0 * multiplier);
const Radius cornerRadiusMD = Radius.circular(16.0 * multiplier);
const Radius cornerRadiusLG = Radius.circular(32.0 * multiplier);
const Radius cornerRadiusMax = Radius.circular(1000.0 * multiplier);

const double textXXL = 36.0 * multiplier;
const double textXL = 20.0 * multiplier;
const double textLG = 18.0 * multiplier;
const double textMD = 15.0 * multiplier;
const double textSM = 13.0 * multiplier;
const double textXS = 11.0 * multiplier;
const double textXXS = 10.0 * multiplier;

const double spaceXXXXS = 2.0 * multiplier;
const double spaceXXXS = 4.0 * multiplier;
const double spaceXXS = 6.0 * multiplier;
const double spaceXS = 8.0 * multiplier;
const double spaceSM = 12.0 * multiplier;
const double spaceMD = 16.0 * multiplier;
const double spaceLG = 32.0 * multiplier;
const double spaceXL = 48.0 * multiplier;
const double spaceXXL = 64.0 * multiplier;

const Duration animShort = Duration(milliseconds: 150);
const Duration animFast = Duration(milliseconds: 200);
const Duration animMedium = Duration(milliseconds: 400);
const Duration animSlow = Duration(milliseconds: 500);

// --- Material 3 typescale aliases ---------------------------------------
// Map to the existing custom text constants so the M3 type ramp can be
// applied consistently across the app. Sizes follow the M3 spec ratios
// while continuing to honour the project-wide `multiplier` scaling.
const double m3DisplaySmall = textXXL;        // 36 sp
const double m3HeadlineMedium = textXL + 4.0; // ~24 sp
const double m3HeadlineSmall = textXL;        // 20 sp
const double m3TitleLarge = textLG;           // 18 sp
const double m3TitleMedium = textMD + 1.0;    // ~16 sp
const double m3BodyLarge = textMD + 1.0;      // ~16 sp
const double m3BodyMedium = textMD;           // 15 sp
const double m3LabelLarge = textSM + 1.0;     // ~14 sp
const double m3LabelMedium = textSM;          // 13 sp
const double m3LabelSmall = textXS;           // 11 sp
