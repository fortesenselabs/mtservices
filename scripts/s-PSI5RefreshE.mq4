//IIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIII+
//|                                                                 s-PSI@Refresh.mq4 |
//|                                       Copyright © 2012, Igor Stepovoi aka TarasBY |
//|                                                                taras_bulba@tut.by |
//|                                                                                   |
//IIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIII+
//|   This product is intended for non-commercial use.  The publication is only allo- |
//|wed when you specify the name of the author (TarasBY). Edit the source code is va- |
//|lid only under condition of preservation of the text, links and author's name.     |
//|   Selling a script or(and) parts of it PROHIBITED.                                |
//|   The author is not liable for any damages resulting from the use of a script.    |
//|   For all matters relating to the work of the script, comments or suggestions for |
//|their improvement in the contact Skype: TarasBY or e-mail.                         |
//IIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIII+
#property copyright "Copyright © 2008-12, TarasBY WM R418875277808; Z670270286972"
#property link      "taras_bulba@tut.by"
//IIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIII+
#define WM_COMMAND                    0x0111
//IIIIIIIIIIIIIIIIIIIIIII============Out modules============IIIIIIIIIIIIIIIIIIIIIIIIII+
#import "user32.dll"
    int GetAncestor (int hWnd, int gaFlags);
    int PostMessageA (int hWnd, int  Msg, int wParam, int lParam);
    int RegisterWindowMessageA (string lpString);
    int SendMessageA (int hWnd, int Msg, int wParam, int lParam);
#import
//IIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIII+
//|         Script program start function                                             |
//IIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIII+
int start()
{
    int li_handleMT = 0, li_handle = WindowHandle (Symbol(), Period());
//----
    if (li_handle != 0)
    {
        if (IsExpertEnabled())
        {
            datetime ldt_TimeCurrent = TimeCurrent();
            while (!IsConnected() && IsExpertEnabled())
            {
                li_handleMT = fReConnect (li_handle);
                Sleep (2000);
                if (ldt_TimeCurrent < TimeCurrent()) break;
            }
        }
        PostMessageA (li_handle, WM_COMMAND, 33324, 0);
        if (li_handleMT == 0) li_handleMT = GetAncestor (li_handle, 2);
        if (li_handleMT != 0)
        {
            PostMessageA (li_handleMT, WM_COMMAND, 33324, 0);
            SendMessageA (li_handleMT, RegisterWindowMessageA ("MetaTrader4_Internal_Message"), 2, 1);
        }
        else {Alert ("Error. The attempt failed !!!");}
    }
    else {Alert ("NOT handle! The attempt failed !!!");}
//----
    return (0);
}
//IIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIII+
//|          RESCAN                                                                   |
//IIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIII+
int fReConnect (int fi_Handle)
{
    int hMetaTrader = GetAncestor (fi_Handle, 2);
    if (hMetaTrader != 0)
    {PostMessageA (hMetaTrader, WM_COMMAND, 37400, 0);}
    return (hMetaTrader);
}   
//IIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIII+

