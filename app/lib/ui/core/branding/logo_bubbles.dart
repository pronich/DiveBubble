/// One circle in the "B" logo mark, normalized to a 0..1 box (source: 1024x1024 viewBox).
class LogoBubble {
  const LogoBubble(this.cx, this.cy, this.r);

  final double cx;
  final double cy;
  final double r;
}

/// Exact circle centers/radii traced from the brand SVG (Logo.png / logo.svg, 1024x1024 viewBox).
const List<LogoBubble> kLogoBubbles = [
  LogoBubble(311.5 / 1024, 236.5 / 1024, 37.5 / 1024),
  LogoBubble(424 / 1024, 209 / 1024, 75 / 1024),
  LogoBubble(657.5 / 1024, 356.5 / 1024, 62.5 / 1024),
  LogoBubble(348.5 / 1024, 750.5 / 1024, 62.5 / 1024),
  LogoBubble(622 / 1024, 467 / 1024, 55 / 1024),
  LogoBubble(435 / 1024, 840 / 1024, 55 / 1024),
  LogoBubble(694 / 1024, 776 / 1024, 55 / 1024),
  LogoBubble(614 / 1024, 857 / 1024, 50 / 1024),
  LogoBubble(533 / 1024, 514 / 1024, 40 / 1024),
  LogoBubble(453 / 1024, 512 / 1024, 30 / 1024),
  LogoBubble(505 / 1024, 604 / 1024, 30 / 1024),
  LogoBubble(454.5 / 1024, 622.5 / 1024, 17.5 / 1024),
  LogoBubble(693.5 / 1024, 429.5 / 1024, 17.5 / 1024),
  LogoBubble(500.5 / 1024, 133.5 / 1024, 17.5 / 1024),
  LogoBubble(303.5 / 1024, 889.5 / 1024, 17.5 / 1024),
  LogoBubble(303.5 / 1024, 491.5 / 1024, 17.5 / 1024),
  LogoBubble(318 / 1024, 444 / 1024, 25 / 1024),
  LogoBubble(349 / 1024, 865 / 1024, 25 / 1024),
  LogoBubble(525 / 1024, 877 / 1024, 30 / 1024),
  LogoBubble(383 / 1024, 482 / 1024, 40 / 1024),
  LogoBubble(570.5 / 1024, 236.5 / 1024, 87.5 / 1024),
  LogoBubble(639 / 1024, 634 / 1024, 100 / 1024),
  LogoBubble(349 / 1024, 344 / 1024, 75 / 1024),
  LogoBubble(354 / 1024, 608 / 1024, 80 / 1024),
];

/// The two light-blue highlight arcs on the two largest bubbles, transcribed from the brand SVG.
/// Coordinates are in the same 1024x1024 source space as [kLogoBubbles] (divide by 1024 to normalize).
const List<String> kLogoHighlightPaths = [
  'M567.768 166.196C568.333 165.426 569.155 164.893 570.104 164.78C574.955 164.2 591.309 163.455 610 176C629.045 188.783 631.86 205.722 632.276 210.45C632.349 211.281 632.082 212.085 631.588 212.758C629.588 215.486 625.031 214.645 623.823 211.486C620.833 203.665 614.943 191.986 604.5 184C593.782 175.804 579.977 173.596 571.237 173.083C567.915 172.888 565.8 168.88 567.768 166.196Z',
  'M630.698 554.271C631.468 553.221 632.655 552.576 633.956 552.624C640.177 552.857 659.994 555.023 684.816 572.082C710.001 589.392 716.621 608.525 718.117 614.349C718.409 615.484 718.118 616.655 717.425 617.601C715.346 620.435 710.795 619.907 709.198 616.775C704.539 607.64 694.928 591.889 679.402 580.145C663.532 568.143 644.387 563.451 633.872 561.685C630.484 561.115 628.666 557.041 630.698 554.271Z',
];
