import QRCode from "qrcode";
import { APP_LAUNCH_URL } from "@/config/appLaunch";

const DARK = "#061f4a"; // brand-navy
const LIGHT = "#ffffff";
const MODULE_SIZE = 10;
const QUIET_ZONE = 4; // modules, per QR spec recommendation

// Builds the QR code as raw SVG markup (no wrapping <svg> tag, so callers can size
// it freely via a viewBox) plus the square viewBox dimension it was drawn at.
export async function buildAppQrSvg(): Promise<{ dim: number; markup: string }> {
  const qr = QRCode.create(APP_LAUNCH_URL, { errorCorrectionLevel: "M" });
  const N = qr.modules.size;
  const data = qr.modules.data;

  const dim = (N + QUIET_ZONE * 2) * MODULE_SIZE;
  const offset = QUIET_ZONE * MODULE_SIZE;

  let modules = "";
  for (let y = 0; y < N; y++) {
    for (let x = 0; x < N; x++) {
      if (!data[y * N + x]) continue;
      const px = offset + x * MODULE_SIZE;
      const py = offset + y * MODULE_SIZE;
      modules += `<rect x="${px}" y="${py}" width="${MODULE_SIZE}" height="${MODULE_SIZE}" rx="${MODULE_SIZE * 0.22}" fill="${DARK}"/>`;
    }
  }

  return { dim, markup: `<rect width="${dim}" height="${dim}" fill="${LIGHT}"/>${modules}` };
}
