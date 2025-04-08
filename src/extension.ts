import * as vscode from "vscode";
import { execSync } from "child_process";
import * as fs from "fs";
import * as os from "os";
import * as path from "path";

export function activate(context: vscode.ExtensionContext) {
  // Registrar el formateador de documentos
  vscode.languages.registerDocumentFormattingEditProvider("foxpro", {
    provideDocumentFormattingEdits(
      document: vscode.TextDocument
    ): vscode.TextEdit[] {
      const text = document.getText();

      // Crear archivo temporal
      const tempFilePath = path.join(os.tmpdir(), "tempCode.prg");
      fs.writeFileSync(tempFilePath, text);

      // Ejecutar el formateador y obtener el texto formateado
      const formattedText = formatWithVisualFoxProSync(tempFilePath);

      const fullRange = new vscode.Range(
        document.positionAt(0),
        document.positionAt(text.length)
      );

      // Eliminar archivo temporal
      fs.unlinkSync(tempFilePath);

      return [vscode.TextEdit.replace(fullRange, formattedText)];
    },
  });
}

function formatWithVisualFoxProSync(filePath: string): string {
  const executablePath = path.join(__dirname, "bin", "vfpbeautify.exe");
  const fllPath = path.join(__dirname, "bin", "fd3.fll");
  const command = `${executablePath} "${filePath}|${fllPath}"`;
  try {
    const stdout = execSync(command);
    return stdout.toString();
  } catch (error) {
    if (error instanceof Error) {
      console.error(`Error: ${error.message}`);
    } else {
      console.error(`Error: ${String(error)}`);
    }
    return '';
  }
}

export function deactivate() {}
