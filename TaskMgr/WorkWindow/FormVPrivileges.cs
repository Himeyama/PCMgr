using PCMgr.Lanuages;
using System;
using System.Collections;
using System.Drawing;
using System.Runtime.InteropServices;
using System.Threading;
using System.Windows.Forms;

namespace PCMgr.WorkWindow
{
    public partial class FormVPrivilege : Form
    {
        public FormVPrivilege(uint pid, string name)
        {
            InitializeComponent();
            currentPid = pid;
            currentName = name;
        }

        private string currentName = "";
        private uint currentPid = 0;

        [DllImport(NativeMethods.COREDLLNAME, CallingConvention = CallingConvention.Cdecl)]
        private static extern bool MEnumProcessPrivileges(uint pid, IntPtr callback);

        private IntPtr CallbackPtr = IntPtr.Zero;
        private EnumPrivilegesCallBack Callback;

        [UnmanagedFunctionPointer(CallingConvention.Cdecl)]
        private delegate void EnumPrivilegesCallBack(IntPtr name);

        private void FormVHandles_Load(object sender, EventArgs e)
        {
            NativeMethods.MAppWorkCall3(182, listView1.Handle, IntPtr.Zero);
            listView1.ListViewItemSorter = new ListViewItemComparer();

            Callback = _EnumPrivilegesCallBack;
            CallbackPtr = Marshal.GetFunctionPointerForDelegate(Callback);
        }
        private void _EnumPrivilegesCallBack(IntPtr name)
        {
            bool blue = false;
            string strName = Marshal.PtrToStringUni(name);
            ListViewItem li = new ListViewItem(strName);
            li.Tag = strName;
            if (LanuageMgr.IsChinese || (LanuageMgr.CurrentLanuage != null && LanuageMgr.CurrentLanuage.StartsWith("ja", StringComparison.OrdinalIgnoreCase)))
                li.SubItems.Add(GetPrivilegeDescripition(strName, out blue));
            if (blue)
            {
                li.SubItems[0].ForeColor = Color.Blue;
                li.SubItems[1].ForeColor = Color.Blue;
            }
            listView1.Invoke(new Action(delegate {
                listView1.Items.Add(li);
            }));
        }

        private string GetPrivilegeDescripition(string s, out bool blue)
        {
            blue = false;
            bool useJapanese = LanuageMgr.CurrentLanuage != null && LanuageMgr.CurrentLanuage.StartsWith("ja", StringComparison.OrdinalIgnoreCase);
            switch (s)
            {
                case "SeShutdownPrivilege":
                    blue = true;
                    return useJapanese ? "このプログラムにはコンピューターを終了する権限があります" : "此程序有关闭计算机的权限";
                case "SeDebugPrivilege": return useJapanese ? "デバッグ権限" : "调试程序权限";
                case "SeAuditPrivilege": return useJapanese ? "セキュリティ監査を生成し、項目をセキュリティログに追加できます" : "产生安全审核,允许将条目添加到安全日志.";
                case "SeRemoteShutdownPrivilege": return useJapanese ? "このプログラムにはリモート コンピューターを終了する権限があります" : "此程序有关闭远程计算机的权限";
                case "SeIncreaseWorkingSetPrivilege":
                    blue = true;
                    return useJapanese ? "このプログラムにはメモリ ワーキング セットを増やす権限があります" : "此程序有增加其内存工作集的权限";
                case "SeTimeZonePrivilege":
                    blue = true;
                    return useJapanese ? "このプログラムにはコンピューターのタイムゾーンを設定する権限があります" : "此程序有设置计算机时区的权限";
                case "SeCreateSymbolicLinkPrivilege": return useJapanese ? "このプログラムにはシンボリック リンクを作成する権限があります" : "此程序有创建符号链接的权限";
                case "SeLoadDriverPrivilege":
                    blue = true;
                    return useJapanese ? "このプログラムにはドライバーを読み込む権限があります" : "此程序有加载驱动的权限";
                case "SeBackupPrivilege":
                    return useJapanese ? "このプログラムには、ファイルやフォルダーを列挙・実行・読み取りし、そのすべての情報を取得する権限があります" : "程序具有遍历，执行文件，读取文件和文件夹所有信息的权限";
                case "SeCreateTokenPrivilege":
                    return useJapanese ? "プロセスが NtCreateToken() や他のトークン作成 API を呼び出してアクセス トークンを作成できます" : "允许进程调用 NtCreateToken() 或者是其他的Token-Creating APIs创建一个访问令牌";
                case "SeAssignPrimaryTokenPrivilege":
                    return useJapanese ? "プロセス レベルのトークンを置き換え、起動済みの子プロセスに関連付けられた既定のトークンを置き換えてプロセスを初期化できます" : "替换进程级记号，允许初始化一个进程,以取代与已启动的子进程相关的默认令牌.";
                case "SeChangeNotifyPrivilege":
                    blue = true;
                    return useJapanese ? "列挙チェックを省略し、ユーザーがディレクトリを移動できますが、フォルダーの内容は一覧表示できません" : "跳过遍历检查，允许用户来回移动目录，但是不能列出文件夹的内容.";
                case "SeSystemEnvironmentPrivilege":
                    blue = true;
                    return useJapanese ? "このプログラムには環境変数と SET コマンドを表示・変更する権限があります" : "允许程序查看、修改环境变量和SET命令.";
                case "SeTakeOwnershipPrivilege":
                    blue = true;
                    return useJapanese ? "このプログラムには、Active Directory のオブジェクト、ファイル、フォルダー、プリンター、レジストリ項目、プロセス、スレッドを含むファイルまたはオブジェクトの所有権を取得する権限があります" : "允许程序获得文件或对象的所有权,包括 Active Directory 对象,文件和文件夹,打印机,注册表项,进程和线程.";
                case "SeTcbPrivilege":
                    blue = true;
                    return useJapanese ? "このプログラムには OS として動作し、OS の一部として扱われる権限があります" : "允许程序以操作系统方式操作，成为操作系统的一部分.";
                default:
                    break;
            }
            return "";
        }


        private void 刷新ToolStripMenuItem_Click(object sender, EventArgs e)
        {
            if (currentPid >= 4)
            {
                labelEnuming.Show();
                listView1.Items.Clear();
                new Thread(EnumHandles).Start();
            }
        }
        private void 取消权限ToolStripMenuItem_Click(object sender, EventArgs e)
        {

        }

        private void EnumHandles()
        {
            Invoke(new Action(delegate {
                listView1.Hide();
                MEnumProcessPrivileges(currentPid, CallbackPtr);
                labelEnuming.Hide();
                listView1.Show();
            }));
        }

        public class ListViewItemComparer : IComparer
        {
            private int col;
            private bool asdening = false;

            public int SortColum { get { return col; } set { col = value; } }
            public bool Asdening { get { return asdening; } set { asdening = value; } }

            public int Compare(object x, object y)
            {
                int returnVal = -1;
                if (((ListViewItem)x).SubItems[col].Text == ((ListViewItem)y).SubItems[col].Text) return -1;
                returnVal = String.Compare(((ListViewItem)x).SubItems[col].Text, ((ListViewItem)y).SubItems[col].Text);
                if (asdening) returnVal = -returnVal;
                return returnVal;
            }
        }

        private void listView1_KeyDown(object sender, KeyEventArgs e)
        {
            if (e.KeyCode == Keys.Apps)
            {
                if (listView1.SelectedItems.Count > 0)
                {
                    ListViewItem item = listView1.SelectedItems[0];
                    Point p = item.Position; p.X = 0;
                    p = listView1.PointToScreen(p);
                    contextMenuStrip1.Show(p);
                }
            }
        }
        private void listView1_MouseClick(object sender, MouseEventArgs e)
        {
            if (e.Button == MouseButtons.Right && listView1.SelectedItems.Count > 0)
                contextMenuStrip1.Show(MousePosition);
        }
        private void listView1_ColumnClick(object sender, ColumnClickEventArgs e)
        {
            ((ListViewItemComparer)listView1.ListViewItemSorter).Asdening = !((ListViewItemComparer)listView1.ListViewItemSorter).Asdening;
            ((ListViewItemComparer)listView1.ListViewItemSorter).SortColum = e.Column;
            listView1.Sort();
        }

        private void FormVHandles_Shown(object sender, EventArgs e)
        {
            刷新ToolStripMenuItem_Click(sender, e);
            labelEnuming.Hide();
        }
    }
}
