using PCMgr.Aero.TaskDialog;
using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Drawing;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Windows.Forms;

namespace PCMgr.WorkWindow
{
    public partial class FormHelp : Form
    {
        public FormHelp()
        {
            InitializeComponent();
        }

        private void FormHelp_Load(object sender, EventArgs e)
        {
            if (!NativeMethods.MREG_IsCurrentIEVersionOK(11000, NativeMethods.MAppGetName()))
                if(!NativeMethods.MREG_SetCurrentIEVersion(11000, NativeMethods.MAppGetName()))
                {
                    TaskDialog t = new TaskDialog("このページは開けません", "エラー");
                    t.Content = "お使いの IE のバージョンが古いため、このページを開けません。他のブラウザーでオンライン ヘルプにアクセスすることもできます：<A HREF=\"http://127.0.0.1/softs/pcmgr/help/\">オンライン ヘルプ ドキュメント</A>";
                    t.EnableHyperlinks = true;
                    t.Show(this);
                }

            webBrowser1.ObjectForScripting = this;
            webBrowser1.Navigate("http://127.0.0.1/softs/pcmgr/help/");
        }
    }
}
