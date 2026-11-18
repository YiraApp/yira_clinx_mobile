// Phosphor icons (https://phosphoricons.com, MIT licence, see
// assets/fonts/phosphor/LICENSE), bundled locally.
//
// The phosphor_flutter package (2.1.0, the latest) subclasses IconData, which
// Flutter no longer allows, so its Dart code does not compile. This file keeps
// the same class names with plain IconData constants for the icons the app
// uses. To add one, copy its code point from the package source or
// https://github.com/phosphor-icons/flutter and add it below.
//
// Fonts are declared in pubspec.yaml as PhosphorBold, PhosphorFill and
// PhosphorDuotone.
//
// The names now point at Hugeicons stroke-rounded glyphs (huge_icons.dart),
// the app's single icon style. The Phosphor fonts remain only for the
// duotone backgrounds map below.

import 'package:flutter/widgets.dart';
import 'package:yiraclinics/core/widgets/huge_icons.dart';

class PhosphorIconsBold {
  PhosphorIconsBold._();

  static const IconData alarm = HugeIcons.alarmClock;
  static const IconData arrowRight = HugeIcons.arrowRight02;
  static const IconData arrowSquareOut = HugeIcons.linkSquare02;
  static const IconData arrowsClockwise = HugeIcons.refresh;
  static const IconData arrowsLeftRight = HugeIcons.arrowDataTransferHorizontal;
  static const IconData bellRinging = HugeIcons.notification02;
  static const IconData bellSimpleSlash = HugeIcons.notificationOff02;
  static const IconData bellSlash = HugeIcons.notificationOff02;
  static const IconData briefcase = HugeIcons.briefcase01;
  static const IconData buildings = HugeIcons.building03;
  static const IconData calendarBlank = HugeIcons.calendar03;
  static const IconData calendarPlus = HugeIcons.calendarAdd01;
  static const IconData camera = HugeIcons.camera01;
  static const IconData caretLeft = HugeIcons.arrowLeft01;
  static const IconData caretRight = HugeIcons.arrowRight01;
  static const IconData caretUpDown = HugeIcons.arrowUpDown;
  static const IconData check = HugeIcons.tick02;
  static const IconData checkCircle = HugeIcons.checkmarkCircle02;
  static const IconData circle = HugeIcons.circle;
  static const IconData clock = HugeIcons.clock01;
  static const IconData clockCounterClockwise = HugeIcons.clock04;
  static const IconData cloudArrowUp = HugeIcons.cloudUpload;
  static const IconData copy = HugeIcons.copy01;
  static const IconData creditCard = HugeIcons.creditCard;
  static const IconData deviceMobile = HugeIcons.smartPhone01;
  static const IconData deviceRotate = HugeIcons.rotate01;
  static const IconData dotsThreeVertical = HugeIcons.moreVertical;
  static const IconData downloadSimple = HugeIcons.download04;
  static const IconData fileDashed = HugeIcons.file02;
  static const IconData filePdf = HugeIcons.pdf02;
  static const IconData fileText = HugeIcons.file02;
  static const IconData forkKnife = HugeIcons.spoonAndFork;
  static const IconData gauge = HugeIcons.dashboardSpeed01;
  static const IconData globe = HugeIcons.globe;
  static const IconData hospital = HugeIcons.hospital01;
  static const IconData image = HugeIcons.image01;
  static const IconData images = HugeIcons.image02;
  static const IconData infinity = HugeIcons.infinity01;
  static const IconData info = HugeIcons.informationCircle;
  static const IconData link = HugeIcons.link01;
  static const IconData linkBreak = HugeIcons.unlink01;
  static const IconData linkSimple = HugeIcons.link01;
  static const IconData lockKeyOpen = HugeIcons.squareUnlock02;
  static const IconData magnifyingGlass = HugeIcons.search01;
  static const IconData minusCircle = HugeIcons.minusSignCircle;
  static const IconData paperclip = HugeIcons.attachment01;
  static const IconData pencilSimple = HugeIcons.pencilEdit01;
  static const IconData phone = HugeIcons.call;
  static const IconData phoneCall = HugeIcons.calling;
  static const IconData pill = HugeIcons.medicine02;
  static const IconData playCircle = HugeIcons.playCircle;
  static const IconData plus = HugeIcons.add01;
  static const IconData plusCircle = HugeIcons.addCircle;
  static const IconData prescription = HugeIcons.prescription;
  static const IconData qrCode = HugeIcons.qrCode;
  static const IconData ruler = HugeIcons.ruler;
  static const IconData scales = HugeIcons.weightScale;
  static const IconData shareNetwork = HugeIcons.share08;
  static const IconData shieldCheck = HugeIcons.securityCheck;
  static const IconData shieldWarning = HugeIcons.shield01;
  static const IconData slidersHorizontal = HugeIcons.filterHorizontal;
  static const IconData stack = HugeIcons.layers01;
  static const IconData stethoscope = HugeIcons.stethoscope;
  static const IconData storefront = HugeIcons.store01;
  static const IconData trash = HugeIcons.delete02;
  static const IconData trendDown = HugeIcons.chartDecrease;
  static const IconData trendUp = HugeIcons.chartIncrease;
  static const IconData user = HugeIcons.user;
  static const IconData userPlus = HugeIcons.userAdd01;
  static const IconData usersThree = HugeIcons.userGroup;
  static const IconData videoCamera = HugeIcons.video02;
  static const IconData warningCircle = HugeIcons.alertCircle;
  static const IconData x = HugeIcons.cancel01;
}

class PhosphorIconsFill {
  PhosphorIconsFill._();

  static const IconData bellRinging = HugeIcons.notification02;
  static const IconData checkCircle = HugeIcons.checkmarkCircle02;
  static const IconData deviceMobile = HugeIcons.smartPhone01;
  static const IconData drop = HugeIcons.droplet;
  static const IconData flame = HugeIcons.fire;
  static const IconData footprints = HugeIcons.workoutRun;
  static const IconData heart = HugeIcons.favourite;
  static const IconData heartbeat = HugeIcons.cardiogram02;
  static const IconData hospital = HugeIcons.hospital01;
  static const IconData info = HugeIcons.informationCircle;
  static const IconData lockSimple = HugeIcons.squareLock02;
  static const IconData mapPin = HugeIcons.location01;
  static const IconData moonStars = HugeIcons.moon02;
  static const IconData path = HugeIcons.route01;
  static const IconData radioButton = HugeIcons.radioButton;
  static const IconData scales = HugeIcons.weightScale;
  static const IconData sealCheck = HugeIcons.checkmarkBadge01;
  static const IconData sparkle = HugeIcons.sparkles;
  static const IconData sun = HugeIcons.sun03;
  static const IconData sunHorizon = HugeIcons.sunrise;
}

class PhosphorIconsDuotone {
  PhosphorIconsDuotone._();

  static const IconData alarm = HugeIcons.alarmClock;
  static const IconData bank = HugeIcons.bank;
  static const IconData bed = HugeIcons.bed;
  static const IconData bell = HugeIcons.notification02;
  static const IconData bellRinging = HugeIcons.notification02;
  static const IconData bellSimpleSlash = HugeIcons.notificationOff02;
  static const IconData bellSlash = HugeIcons.notificationOff02;
  static const IconData bowlFood = HugeIcons.riceBowl01;
  static const IconData calendarCheck = HugeIcons.calendarCheckIn01;
  static const IconData calendarX = HugeIcons.calendarRemove01;
  static const IconData camera = HugeIcons.camera01;
  static const IconData chatCircleText = HugeIcons.bubbleChat;
  static const IconData checkCircle = HugeIcons.checkmarkCircle02;
  static const IconData cloudSlash = HugeIcons.wifiOff01;
  static const IconData filePdf = HugeIcons.pdf02;
  static const IconData fileText = HugeIcons.file02;
  static const IconData firstAidKit = HugeIcons.firstAidKit;
  static const IconData flask = HugeIcons.testTube01;
  static const IconData heartbeat = HugeIcons.cardiogram02;
  static const IconData hospital = HugeIcons.hospital01;
  static const IconData images = HugeIcons.image02;
  static const IconData lightbulb = HugeIcons.bulb;
  static const IconData link = HugeIcons.link01;
  static const IconData magnifyingGlass = HugeIcons.search01;
  static const IconData notepad = HugeIcons.note;
  static const IconData pictureInpicture = HugeIcons.layers01;
  static const IconData pill = HugeIcons.medicine02;
  static const IconData prescription = HugeIcons.prescription;
  static const IconData receipt = HugeIcons.invoice01;
  static const IconData scan = HugeIcons.scanImage;
  static const IconData shareNetwork = HugeIcons.share08;
  static const IconData shieldCheck = HugeIcons.securityCheck;
  static const IconData shieldPlus = HugeIcons.shield01;
  static const IconData signOut = HugeIcons.logout02;
  static const IconData sparkle = HugeIcons.sparkles;
  static const IconData stethoscope = HugeIcons.stethoscope;
  static const IconData tag = HugeIcons.tag01;
  static const IconData trash = HugeIcons.delete02;
  static const IconData umbrella = HugeIcons.umbrella;
  static const IconData usersThree = HugeIcons.userGroup;
  static const IconData videoCamera = HugeIcons.video02;
  static const IconData warningCircle = HugeIcons.alertCircle;
  static const IconData xCircle = HugeIcons.cancelCircle;
  static const IconData drop = HugeIcons.droplet;
  static const IconData butterfly = HugeIcons.leaf01;
  static const IconData genderFemale = HugeIcons.femaleSymbol;
  static const IconData personSimple = HugeIcons.user;
  static const IconData dna = HugeIcons.dna01;
  static const IconData brain = HugeIcons.brain;
  static const IconData bone = HugeIcons.bone01;
  static const IconData virus = HugeIcons.bacteria;
  static const IconData thermometer = HugeIcons.thermometer;
  static const IconData testTube = HugeIcons.testTube01;
  static const IconData syringe = HugeIcons.injection;
  static const IconData heart = HugeIcons.favourite;
  static const IconData sun = HugeIcons.sun03;
  static const IconData microscope = HugeIcons.microscope;
  static const IconData eye = HugeIcons.view;
}

/// The background glyph drawn under each two-tone icon, by code point.
const Map<int, IconData> _duotoneBackground = {
  0xe211: IconData(0xe210, fontFamily: 'PhosphorDuotone'),
  0xea6f: IconData(0xea6e, fontFamily: 'PhosphorDuotone'),
  0xe6e1: IconData(0xe6e0, fontFamily: 'PhosphorDuotone'),
  0xe72f: IconData(0xe72e, fontFamily: 'PhosphorDuotone'),
  0xe925: IconData(0xe924, fontFamily: 'PhosphorDuotone'),
  0xe74f: IconData(0xe74e, fontFamily: 'PhosphorDuotone'),
  0xe7f3: IconData(0xe7f2, fontFamily: 'PhosphorDuotone'),
  0xe7d7: IconData(0xe7d6, fontFamily: 'PhosphorDuotone'),
  0xe5c7: IconData(0xe5c6, fontFamily: 'PhosphorDuotone'),
  0xe7a1: IconData(0xe7a0, fontFamily: 'PhosphorDuotone'),
  0xe969: IconData(0xe968, fontFamily: 'PhosphorDuotone'),
  0xe2a9: IconData(0xe2a8, fontFamily: 'PhosphorDuotone'),
  0xe473: IconData(0xe472, fontFamily: 'PhosphorDuotone'),
  0xec7b: IconData(0xec7a, fontFamily: 'PhosphorDuotone'),
  0xe221: IconData(0xe220, fontFamily: 'PhosphorDuotone'),
  0xe007: IconData(0xe006, fontFamily: 'PhosphorDuotone'),
  0xe0b5: IconData(0xe0b4, fontFamily: 'PhosphorDuotone'),
  0xe0cd: IconData(0xe0cc, fontFamily: 'PhosphorDuotone'),
  0xe0cf: IconData(0xe0ce, fontFamily: 'PhosphorDuotone'),
  0xe0d3: IconData(0xe0d2, fontFamily: 'PhosphorDuotone'),
  0xe0d5: IconData(0xe0d4, fontFamily: 'PhosphorDuotone'),
  0xe10d: IconData(0xe10c, fontFamily: 'PhosphorDuotone'),
  0xe10f: IconData(0xe10e, fontFamily: 'PhosphorDuotone'),
  0xe16f: IconData(0xe16e, fontFamily: 'PhosphorDuotone'),
  0xe185: IconData(0xe184, fontFamily: 'PhosphorDuotone'),
  0xe1b7: IconData(0xe1b6, fontFamily: 'PhosphorDuotone'),
  0xe23b: IconData(0xe23a, fontFamily: 'PhosphorDuotone'),
  0xe2ad: IconData(0xe2ac, fontFamily: 'PhosphorDuotone'),
  0xe2dd: IconData(0xe2dc, fontFamily: 'PhosphorDuotone'),
  0xe2e3: IconData(0xe2e2, fontFamily: 'PhosphorDuotone'),
  0xe30d: IconData(0xe30c, fontFamily: 'PhosphorDuotone'),
  0xe3f1: IconData(0xe3ec, fontFamily: 'PhosphorDuotone'),
  0xe40b: IconData(0xe408, fontFamily: 'PhosphorDuotone'),
  0xe40f: IconData(0xe40c, fontFamily: 'PhosphorDuotone'),
  0xe42b: IconData(0xe42a, fontFamily: 'PhosphorDuotone'),
  0xe479: IconData(0xe478, fontFamily: 'PhosphorDuotone'),
  0xe4a7: IconData(0xe4a6, fontFamily: 'PhosphorDuotone'),
  0xe4db: IconData(0xe4da, fontFamily: 'PhosphorDuotone'),
  0xe4e3: IconData(0xe4e2, fontFamily: 'PhosphorDuotone'),
  0xe4f9: IconData(0xe4f8, fontFamily: 'PhosphorDuotone'),
  0xe571: IconData(0xe570, fontFamily: 'PhosphorDuotone'),
  0xe5e9: IconData(0xe5e8, fontFamily: 'PhosphorDuotone'),
  0xe63f: IconData(0xe63e, fontFamily: 'PhosphorDuotone'),
  0xe64d: IconData(0xe64c, fontFamily: 'PhosphorDuotone'),
  0xe685: IconData(0xe684, fontFamily: 'PhosphorDuotone'),
  0xe68f: IconData(0xe68e, fontFamily: 'PhosphorDuotone'),
  0xe6a3: IconData(0xe6a2, fontFamily: 'PhosphorDuotone'),
  0xe701: IconData(0xe700, fontFamily: 'PhosphorDuotone'),
  0xe703: IconData(0xe702, fontFamily: 'PhosphorDuotone'),
  0xe707: IconData(0xe706, fontFamily: 'PhosphorDuotone'),
  0xe713: IconData(0xe712, fontFamily: 'PhosphorDuotone'),
  0xe79f: IconData(0xe79e, fontFamily: 'PhosphorDuotone'),
  0xe7a3: IconData(0xe7a2, fontFamily: 'PhosphorDuotone'),
  0xe7eb: IconData(0xe7ea, fontFamily: 'PhosphorDuotone'),
  0xe837: IconData(0xe836, fontFamily: 'PhosphorDuotone'),
  0xe845: IconData(0xe844, fontFamily: 'PhosphorDuotone'),
  0xeaa5: IconData(0xeaa4, fontFamily: 'PhosphorDuotone'),
  0xebb7: IconData(0xebb6, fontFamily: 'PhosphorDuotone'),
};


/// An [Icon] that also draws the soft background layer of two-tone
/// (PhosphorIconsDuotone) icons. Other icons render exactly like [Icon].
class PhosphorIcon extends Icon {
  const PhosphorIcon(
    super.icon, {
    super.key,
    super.size,
    super.color,
    super.semanticLabel,
    super.shadows,
    this.duotoneSecondaryOpacity = 0.22,
    this.duotoneSecondaryColor,
  });

  final double duotoneSecondaryOpacity;
  final Color? duotoneSecondaryColor;

  @override
  Widget build(BuildContext context) {
    final data = icon;
    final IconData? background = data != null && data.fontFamily == 'PhosphorDuotone' ? _duotoneBackground[data.codePoint] : null;
    if (background == null) return super.build(context);
    return Stack(
      alignment: Alignment.center,
      children: [
        Opacity(
          opacity: duotoneSecondaryOpacity,
          child: Icon(
            background,
            size: size,
            color: duotoneSecondaryColor ?? color,
          ),
        ),
        super.build(context),
      ],
    );
  }
}
