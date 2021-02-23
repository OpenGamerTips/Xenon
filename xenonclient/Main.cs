using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Data;
using System.Diagnostics;
using System.Drawing;
using System.IO;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Windows.Forms;

namespace XenonClient
{
    public partial class Main : Form
    {
        public Pipe ExploitPipe;
        public Main()
        {
            InitializeComponent();
        }

        private void Main_Load(object sender, EventArgs e)
        {
            ExploitPipe = new Pipe("XenonPipe");
        }

        private void button2_Click(object sender, EventArgs e)
        {
            Injector.InjectDLL(Process.GetProcessesByName("RobloxPlayerBeta")[0], Path.GetFullPath("..\\XenonDll\\XenonDll.dll"));
        }

        private void button1_Click(object sender, EventArgs e)
        {
            ExploitPipe.SendData(richTextBox1.Text);
        }
    }
}
