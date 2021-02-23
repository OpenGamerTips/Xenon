using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.IO;
using System.IO.Pipes;
using System.Linq;
using System.Text;
using System.Threading;
using System.Threading.Tasks;
using System.Windows.Forms;

namespace XenonClient
{
    public class Pipe
    {
        private string PipeName;
        public Pipe(string Name)
        {
            PipeName = Name;
        }

        public bool Exists()
        {
            return Directory.GetFiles(@"\\.\pipe\").Contains($@"\\.\pipe\{PipeName}");
        }

        public void WaitUntilExists()
        {
            while (!Exists())
            {
                Thread.Sleep(100);
            }
        }

        public bool SendData(string Data)
        {
            try
            {
                using (NamedPipeClientStream Client = new NamedPipeClientStream(".", PipeName, PipeDirection.Out))
                {
                    Client.Connect();
                    using (StreamWriter Writer = new StreamWriter(Client, Encoding.Default, 1024))
                    {
                        Writer.Write(Data);
                        Writer.Flush(); // Flush
                    }
                    Client.Dispose();
                }
                return true;
            }
            catch (IOException)
            {
                MessageBox.Show("There was a problem accessing the pipe.", "NamedPipes | Predicted Error", MessageBoxButtons.OK, MessageBoxIcon.Warning);
                return false;
            }
            catch (Exception Ex)
            {
                MessageBox.Show("An unpredicted exception was thrown in 'SendData'.\nDeveloper Info:\nError was not from IO.\nLine: " + new StackTrace(Ex, true).GetFrame(0).GetFileLineNumber() + "\nException Type: " + Ex.GetType().Name + "\nException Message: " + Ex.Message, "NamedPipes | Critical Error", MessageBoxButtons.OK, MessageBoxIcon.Error);
                return false;
            }
        }
    }
}
