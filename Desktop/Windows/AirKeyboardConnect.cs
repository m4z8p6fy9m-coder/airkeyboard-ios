// Original AirKeyboard companion. Framework-only; no bundled signer, drivers or Apple credentials.
using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Drawing;
using System.IO;
using System.IO.Compression;
using System.Linq;
using System.Management;
using System.ServiceProcess;
using System.Text;
using System.Text.RegularExpressions;
using System.Threading.Tasks;
using System.Windows.Forms;
using Microsoft.Win32;

namespace AirKeyboardConnect
{
    internal static class Program
    {
        [STAThread]
        private static int Main(string[] args)
        {
            if (args.Length == 2 && args[0] == "--self-test")
            {
                try { SelfTests.Run(args[1]); return 0; }
                catch (Exception error) { File.WriteAllText(args[1], "FAIL: " + error.ToString()); return 1; }
            }
            Application.EnableVisualStyles();
            Application.SetCompatibleTextRenderingDefault(false);
            if (args.Length == 2 && args[0] == "--render-preview")
            {
                using (ConnectForm form = new ConnectForm(true))
                using (Bitmap bitmap = new Bitmap(form.Width, form.Height)) {
                    form.ShowInTaskbar = false; form.Opacity = 0;
                    form.Show(); form.PerformLayout(); Application.DoEvents();
                    form.DrawToBitmap(bitmap, new Rectangle(0, 0, form.Width, form.Height));
                    bitmap.Save(args[1], System.Drawing.Imaging.ImageFormat.Png);
                    form.Hide();
                }
                return 0;
            }
            Application.Run(new ConnectForm());
            return 0;
        }
    }

    internal sealed class Inspection
    {
        public string Path;
        public string Summary;
    }

    internal static class IpaInspector
    {
        internal const string App = "Payload/AirKeyboard.app/";
        internal static readonly string[] Executables = {
            App + "AirKeyboard",
            App + "PlugIns/AirKeyboardKeyboard.appex/AirKeyboardKeyboard",
            App + "PlugIns/AirKeyboardWidgets.appex/AirKeyboardWidgets"
        };

        internal static Inspection Inspect(string path)
        {
            if (!String.Equals(System.IO.Path.GetExtension(path), ".ipa", StringComparison.OrdinalIgnoreCase))
                throw new InvalidDataException("Bitte eine AirKeyboard .ipa-Datei aus dem Build-Workflow auswÃ¤hlen.");
            FileInfo file = new FileInfo(path);
            if (!file.Exists || file.Length == 0 || file.Length > 536870912L)
                throw new InvalidDataException("IPA fehlt, ist leer oder grÃ¶ÃŸer als 512 MB.");
            using (ZipArchive zip = ZipFile.OpenRead(path))
            {
                if (zip.Entries.Count > 50000) throw new InvalidDataException("Zu viele EintrÃ¤ge in der IPA.");
                HashSet<string> names = new HashSet<string>(StringComparer.OrdinalIgnoreCase);
                long total = 0;
                foreach (ZipArchiveEntry entry in zip.Entries)
                {
                    string name = entry.FullName;
                    if (name.StartsWith("/") || name.IndexOf('\\') >= 0 || name.IndexOf(':') >= 0 ||
                        name.Split('/').Any(p => p == ".." || p == ".") || name.IndexOf('\0') >= 0 || !names.Add(name))
                        throw new InvalidDataException("Unsichere oder doppelte Archivpfade. Die IPA wird nicht geÃ¶ffnet.");
                    if (((entry.ExternalAttributes >> 16) & 0xF000) == 0xA000)
                        throw new InvalidDataException("Symbolische Links werden in diesem AirKeyboard-Paket nicht unterstÃ¼tzt.");
                    checked { total += entry.Length; }
                    if (total > 1073741824L) throw new InvalidDataException("Entpackte GrÃ¶ÃŸe Ã¼ber 1 GB.");
                }
                foreach (string executable in Executables)
                {
                    ZipArchiveEntry info = zip.GetEntry(executable.Substring(0, executable.LastIndexOf('/') + 1) + "Info.plist");
                    if (info == null || info.Length == 0 || info.Length > 1048576)
                        throw new InvalidDataException("App oder Erweiterung fehlt: " + executable);
                    ZipArchiveEntry binary = zip.GetEntry(executable);
                    if (binary == null) throw new InvalidDataException("iPhone-Programm fehlt: " + executable);
                    using (Stream stream = binary.Open()) { CheckMachO(stream); }
                }
                return new Inspection {
                    Path = file.FullName,
                    Summary = "iPhone-Paket geprÃ¼ft: App + Tastatur + Widgets vorhanden; alle drei Programme sind ARM64 fÃ¼r iOS.\r\n" +
                              "Signatur, Provisioning und App-Group-Zugriff sind damit noch nicht geprÃ¼ft."
                };
            }
        }

        private static void CheckMachO(Stream stream)
        {
            using (BinaryReader reader = new BinaryReader(stream, Encoding.UTF8, true))
            {
                if (reader.ReadUInt32() != 0xFEEDFACF || reader.ReadUInt32() != 0x0100000C)
                    throw new InvalidDataException("Kein unterstÃ¼tztes ARM64-iPhone-Programm.");
                reader.ReadUInt32();
                if (reader.ReadUInt32() != 2) throw new InvalidDataException("Kein ausfÃ¼hrbares iPhone-Programm.");
                uint commands = reader.ReadUInt32(), commandBytes = reader.ReadUInt32();
                reader.ReadUInt32(); reader.ReadUInt32();
                if (commands == 0 || commands > 4096 || commandBytes > 4194304)
                    throw new InvalidDataException("UngÃ¼ltiger Mach-O-Header.");
                uint consumed = 0;
                bool ios = false;
                for (uint index = 0; index < commands; index++)
                {
                    uint command = reader.ReadUInt32(), size = reader.ReadUInt32();
                    if (size < 8 || size > 1048576 || (size % 8) != 0 || size > commandBytes - consumed)
                        throw new InvalidDataException("UngÃ¼ltige Mach-O-Kommandos.");
                    byte[] data = reader.ReadBytes((int)size - 8);
                    if (data.Length != size - 8) throw new InvalidDataException("Abgeschnittenes iPhone-Programm.");
                    if (command == 0x32)
                    {
                        if (data.Length < 16 || BitConverter.ToUInt32(data, 0) != 2)
                            throw new InvalidDataException("Simulator-Pakete kÃ¶nnen nicht aufs iPhone installiert werden.");
                        ios = true;
                    }
                    consumed += size;
                }
                if (consumed != commandBytes || !ios) throw new InvalidDataException("iOS-Plattformnachweis fehlt.");
            }
        }
    }

    internal sealed class ConnectForm : Form
    {
        private readonly Color ink = Color.FromArgb(18, 27, 34);
        private readonly Color mint = Color.FromArgb(131, 229, 206);
        private readonly Label device = new Label();
        private readonly Label package = new Label();
        private readonly Label drag = new Label();
        private readonly TextBox repository = new TextBox();
        private readonly Button signer = new Button();
        private Inspection inspected;
        private string sideloadly;

        internal ConnectForm(bool previewOnly = false)
        {
            Text = "AirKeyboard Connect";
            StartPosition = FormStartPosition.CenterScreen;
            Size = new Size(850, 830); MinimumSize = new Size(680, 660);
            AutoScaleMode = AutoScaleMode.Dpi;
            Font = new Font("Segoe UI", 10);
            BackColor = ink; ForeColor = Color.White;
            TableLayoutPanel layout = new TableLayoutPanel { Dock = DockStyle.Fill, Padding = new Padding(26), ColumnCount = 1, AutoScroll = true };
            Controls.Add(layout);
            Label title = LabelFor("AIRKEYBOARD\r\nDein iPhone. Dein Design.", 24, true);
            layout.Controls.Add(title);
            layout.Controls.Add(LabelFor("Windows-Verbindung Â· iOS 18+ Â· kein eigener Mac erforderlich", 10, false));

            layout.Controls.Add(LabelFor("1  IPHONE VERBINDEN", 12, true));
            layout.Controls.Add(LabelFor("iPhone per USB anschlieÃŸen, entsperren und â€žDiesem Computer vertrauenâ€œ bestÃ¤tigen.", 10, false));
            device.Text = "USB-Status noch nicht geprÃ¼ft."; PrepareLabel(device);
            layout.Controls.Add(device);
            layout.Controls.Add(ActionButton("USB-GerÃ¤te prÃ¼fen", async delegate { await RefreshDevices(); }));

            layout.Controls.Add(LabelFor("2  KOSTENLOSE BUILDS ÖFFNEN", 12, true));
            layout.Controls.Add(LabelFor("Öffentliches GitHub-Repository (Besitzer/Repository):", 10, false));
            repository.Text = "m4z8p6fy9m-coder/airkeyboard-ios";
            repository.Dock = DockStyle.Top; repository.BackColor = Color.FromArgb(36, 49, 59); repository.ForeColor = Color.White;
            repository.AccessibleName = "GitHub-Repository, Besitzer SchrÃ¤gstrich Repository";
            layout.Controls.Add(repository);
            layout.Controls.Add(ActionButton("IPA-Build auf GitHub Ã¶ffnen", delegate {
                string repo = repository.Text.Trim();
                if (!Regex.IsMatch(repo, @"^[A-Za-z0-9][A-Za-z0-9_.-]{0,99}/[A-Za-z0-9][A-Za-z0-9_.-]{0,99}$"))
                    throw new InvalidOperationException("Trage dein GitHub-Repository als Besitzer/Repository ein. Das Projekt muss dort bereits hochgeladen sein.");
                OpenUrl("https://github.com/" + repo + "/actions/workflows/ci.yml");
            }));
            package.Text = "Noch keine IPA ausgewÃ¤hlt. Die Projekt-ZIP ist keine iPhone-App."; PrepareLabel(package);
            layout.Controls.Add(package);
            layout.Controls.Add(ActionButton("AirKeyboard.ipa auswÃ¤hlen und prÃ¼fen", ChooseIpa));

            layout.Controls.Add(LabelFor("3  OPTIONALE GERÄTE-INSTALLATION", 12, true));
            signer.Text = "Sideloadly starten"; StyleButton(signer);
            signer.Click += delegate { Guard(OpenSigner); };
            layout.Controls.Add(signer);
            layout.Controls.Add(ActionButton("Sideloadly auswÃ¤hlenâ€¦", delegate {
                using (OpenFileDialog picker = new OpenFileDialog { Filter = "Sideloadly|Sideloadly.exe", CheckFileExists = true })
                    if (picker.ShowDialog(this) == DialogResult.OK) sideloadly = picker.FileName;
            }));
            layout.Controls.Add(ActionButton("Offizielle Sideloadly-Downloadseite", delegate { OpenUrl("https://sideloadly.io/"); }));
            drag.Text = "Nach der PrÃ¼fung: IPA von hier in Sideloadly ziehen";
            PrepareLabel(drag); drag.Padding = new Padding(12); drag.BackColor = Color.FromArgb(36, 49, 59);
            drag.Cursor = Cursors.Hand; drag.AccessibleName = "GeprÃ¼fte IPA nach Sideloadly ziehen";
            drag.MouseDown += delegate(object sender, MouseEventArgs args) {
                if (args.Button == MouseButtons.Left && inspected != null)
                    Guard(delegate { drag.DoDragDrop(new DataObject(DataFormats.FileDrop, new string[] { inspected.Path }), DragDropEffects.Copy); });
            };
            layout.Controls.Add(drag);
            layout.Controls.Add(LabelFor("In Sideloadly: iPhone wÃ¤hlen, IPA hineinziehen, Apple-Account eingeben und Start drÃ¼cken. Tastatur- und Widget-Erweiterungen behalten. Zugangsdaten gibst du nur in Sideloadly ein.", 10, false));
            layout.Controls.Add(LabelFor("Danach am iPhone: Einstellungen â†’ Allgemein â†’ Tastatur â†’ Tastaturen â†’ AirKeyboard hinzufÃ¼gen. FÃ¼r eigene TÃ¶ne ist Vollzugriff optional. Gemeinsame Themes brauchen korrekt signierte App Groups; Sideload-KompatibilitÃ¤t ist noch am GerÃ¤t zu testen.", 10, false));
            layout.Controls.Add(LabelFor("Dieser Helfer prÃ¼ft Dateien und Ã¶ffnet den Installationsweg. Er bestÃ¤tigt keine erfolgreiche Installation und verÃ¤ndert keine Apple-SystemoberflÃ¤chen.", 9, false));
            AllowDrop = true;
            DragEnter += delegate(object sender, DragEventArgs args) {
                args.Effect = args.Data.GetDataPresent(DataFormats.FileDrop) ? DragDropEffects.Copy : DragDropEffects.None;
            };
            DragDrop += async delegate(object sender, DragEventArgs args) {
                string[] paths = args.Data.GetData(DataFormats.FileDrop) as string[];
                if (paths != null && paths.Length == 1) await LoadIpa(paths[0]);
            };
            if (!previewOnly) Shown += async delegate {
                sideloadly = FindSigner();
                string bundled = Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "AirKeyboard.ipa");
                if (File.Exists(bundled)) await LoadIpa(bundled);
                await RefreshDevices();
            };
        }

        private void PrepareLabel(Label label)
        {
            label.AutoSize = true; label.MaximumSize = new Size(740, 0); label.Margin = new Padding(0, 6, 0, 12);
        }
        private Label LabelFor(string text, float size, bool bold)
        {
            Label label = new Label { Text = text, Font = new Font("Segoe UI", size, bold ? FontStyle.Bold : FontStyle.Regular) };
            PrepareLabel(label); return label;
        }
        private void StyleButton(Button button)
        {
            button.AutoSize = true; button.MinimumSize = new Size(270, 38); button.FlatStyle = FlatStyle.Flat;
            button.BackColor = mint; button.ForeColor = ink; button.Padding = new Padding(8, 3, 8, 3);
            button.Margin = new Padding(0, 3, 0, 9);
        }
        private Button ActionButton(string text, Action action)
        {
            Button button = new Button { Text = text }; StyleButton(button);
            button.Click += delegate { Guard(action); }; return button;
        }
        private void Guard(Action action)
        {
            try { action(); }
            catch (Exception error) { MessageBox.Show(this, error.Message, "AirKeyboard Connect", MessageBoxButtons.OK, MessageBoxIcon.Information); }
        }
        private async void ChooseIpa()
        {
            using (OpenFileDialog picker = new OpenFileDialog { Filter = "iPhone-App (*.ipa)|*.ipa", CheckFileExists = true })
                if (picker.ShowDialog(this) == DialogResult.OK) await LoadIpa(picker.FileName);
        }
        private async Task LoadIpa(string path)
        {
            inspected = null; package.Text = "IPA wird geprÃ¼ftâ€¦";
            try {
                Inspection result = await Task.Run(() => IpaInspector.Inspect(path));
                inspected = result; package.Text = Path.GetFileName(result.Path) + "\r\n" + result.Summary;
                drag.Text = "AirKeyboard.ipa â†’ in das Sideloadly-Fenster ziehen";
            } catch (Exception error) { package.Text = "IPA nicht verwendbar: " + error.Message; }
        }
        private async Task RefreshDevices()
        {
            device.Text = "Apple-USB-GerÃ¤te werden gesuchtâ€¦";
            try {
                string result = await Task.Run(delegate {
                    bool usb = false, service = false;
                    using (ManagementObjectSearcher search = new ManagementObjectSearcher("SELECT PNPDeviceID FROM Win32_PnPEntity WHERE ConfigManagerErrorCode = 0"))
                    using (ManagementObjectCollection devices = search.Get())
                        foreach (ManagementObject item in devices) using (item) {
                            string id = Convert.ToString(item["PNPDeviceID"]);
                            if (id.StartsWith(@"USB\VID_05AC", StringComparison.OrdinalIgnoreCase)) usb = true;
                        }
                    foreach (ServiceController item in ServiceController.GetServices()) using (item) {
                        if (item.ServiceName.IndexOf("Apple Mobile Device", StringComparison.OrdinalIgnoreCase) >= 0 && item.Status == ServiceControllerStatus.Running) service = true;
                    }
                    return (usb ? "Apple-USB-GerÃ¤t erkannt. iPhone-Vertrauen und Installationsbereitschaft bitte in Sideloadly prÃ¼fen." : "Kein Apple-USB-GerÃ¤t erkannt. Kabel, entsperrtes iPhone und Apple-Treiber prÃ¼fen.") +
                        "\r\nApple Mobile Device Service: " + (service ? "lÃ¤uft" : "nicht als laufend erkannt");
                });
                device.Text = result;
            } catch (Exception error) { device.Text = "USB-PrÃ¼fung nicht mÃ¶glich: " + error.Message; }
        }
        private void OpenSigner()
        {
            if (inspected == null) throw new InvalidOperationException("WÃ¤hle zuerst eine gÃ¼ltige AirKeyboard.ipa aus.");
            // Recheck at handoff: another process may have replaced the selected package.
            IpaInspector.Inspect(inspected.Path);
            if (String.IsNullOrEmpty(sideloadly) || !File.Exists(sideloadly)) {
                OpenUrl("https://sideloadly.io/");
                throw new InvalidOperationException("Installiere Sideloadly von der offiziellen Seite und wÃ¤hle danach Sideloadly.exe aus.");
            }
            Process.Start(new ProcessStartInfo(sideloadly) { UseShellExecute = true });
            package.Text = inspected.Summary + "\r\nSideloadly wurde gestartet. Ziehe die IPA hinein; die Installation ist noch nicht bestÃ¤tigt.";
        }
        private static void OpenUrl(string url) { Process.Start(new ProcessStartInfo(url) { UseShellExecute = true }); }
        private static string FindSigner()
        {
            foreach (RegistryKey root in new RegistryKey[] { Registry.CurrentUser, Registry.LocalMachine })
                using (RegistryKey key = root.OpenSubKey(@"SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\Sideloadly.exe")) {
                    if (key != null) {
                        string value = key.GetValue(null) as string;
                        if (!String.IsNullOrEmpty(value) && File.Exists(value)) return value;
                    }
                }
            foreach (string root in new string[] { Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData), Environment.GetFolderPath(Environment.SpecialFolder.ProgramFiles), Environment.GetFolderPath(Environment.SpecialFolder.ProgramFilesX86) }) {
                string path = Path.Combine(root, "Sideloadly", "Sideloadly.exe");
                if (File.Exists(path)) return path;
            }
            return null;
        }
    }

    internal static class SelfTests
    {
        internal static void Run(string reportPath)
        {
            string folder = Path.Combine(Path.GetTempPath(), "AirKeyboardTests-" + Guid.NewGuid().ToString("N"));
            Directory.CreateDirectory(folder);
            List<string> results = new List<string>();
            try {
                string valid = Fixture(folder, "valid", 2, false, false, false);
                IpaInspector.Inspect(valid); results.Add("PASS: device ARM64 app plus both extensions accepted");
                Reject(Fixture(folder, "simulator", 7, false, false, false), results, "simulator rejected");
                Reject(Fixture(folder, "missing-keyboard", 2, true, false, false), results, "missing keyboard rejected");
                Reject(Fixture(folder, "traversal", 2, false, true, false), results, "unsafe archive path rejected");
                Reject(Fixture(folder, "duplicate", 2, false, false, true), results, "duplicate archive entry rejected");
                string broken = Path.Combine(folder, "broken.ipa"); File.WriteAllText(broken, "not a ZIP");
                Reject(broken, results, "malformed archive rejected");
                string empty = Path.Combine(folder, "empty.ipa"); File.WriteAllBytes(empty, new byte[0]);
                Reject(empty, results, "empty package rejected");
                File.WriteAllText(reportPath, String.Join(Environment.NewLine, results) + Environment.NewLine + "7 checks passed. No iPhone installation performed.");
            } finally { Directory.Delete(folder, true); }
        }
        private static void Reject(string path, List<string> results, string name)
        {
            bool rejected = false;
            try { IpaInspector.Inspect(path); } catch (InvalidDataException) { rejected = true; }
            if (!rejected) throw new Exception("Expected rejection: " + name);
            results.Add("PASS: " + name);
        }
        private static string Fixture(string folder, string name, uint platform, bool omitKeyboard, bool traversal, bool duplicate)
        {
            string path = Path.Combine(folder, name + ".ipa");
            using (ZipArchive zip = ZipFile.Open(path, ZipArchiveMode.Create)) {
                foreach (string executable in IpaInspector.Executables) {
                    if (omitKeyboard && executable.Contains("Keyboard.appex")) continue;
                    using (Stream data = zip.CreateEntry(executable.Substring(0, executable.LastIndexOf('/') + 1) + "Info.plist").Open())
                        data.WriteByte(1);
                    using (Stream data = zip.CreateEntry(executable).Open())
                    using (BinaryWriter writer = new BinaryWriter(data)) {
                        foreach (uint value in new uint[] { 0xFEEDFACF, 0x0100000C, 0, 2, 1, 24, 0, 0, 0x32, 24, platform, 0x00120000, 0x00120000, 0 }) writer.Write(value);
                    }
                }
                if (traversal) zip.CreateEntry("Payload/../../escape");
                if (duplicate) zip.CreateEntry(IpaInspector.Executables[0]);
            }
            return path;
        }
    }
}
