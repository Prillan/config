import Data.Ratio ((%))
import System.IO
import XMonad
import XMonad.Hooks.DynamicLog
import XMonad.Hooks.DynamicLog
import XMonad.Hooks.ManageDocks
import XMonad.Hooks.ManageHelpers
import XMonad.Hooks.SetWMName
import XMonad.Layout.Fullscreen
import XMonad.Layout.Grid
import XMonad.Layout.NoBorders
import XMonad.Layout.Tabbed
import XMonad.Util.EZConfig(additionalKeys)
import XMonad.Util.Run(spawnPipe)
import qualified Codec.Binary.UTF8.String as UTF8
import qualified DBus as D
import qualified DBus.Client as D
import qualified XMonad.StackSet as W

withMobarLayouts =  layoutHook defaultConfig
--                ||| simpleTabbed


data WSpace a b c = WSpace { wspaceNum :: a
                           , wspaceName :: b
                           , wspaceKey :: c }
rawWorkspaces = map (\(n, c, k) -> WSpace n c k) $
  [ (1, "一", xK_1)
  , (2, "二", xK_2)
  , (3, "三", xK_3)
  , (4, "四", xK_4)
  , (5, "五", xK_5)
  , (6, "六", xK_6)
  , (7, "七", xK_7)
  , (8, "八", xK_8)
  , (9, "九", xK_9)
  , (0, "零", xK_0) ]

myWorkspaces = map wspaceName rawWorkspaces

myKeys = [ ((mod4Mask .|. shiftMask, xK_l), spawn "gnome-screensaver-command -l")
         , ((controlMask, xK_Print), spawn "sleep 0.2; scrot -s")
         , ((0, xK_Print), spawn "scrot")]
         ++ workspaceKeys
  where workspaceKeys = do
          wspace <- rawWorkspaces
          let key = wspaceKey wspace
              name = wspaceName wspace
          (f, m) <- [(W.greedyView, 0), (W.shift, shiftMask)]
          pure ((m .|. mod4Mask, key), windows $ f name)

main = do
--    xmproc <- spawnPipe "/home/prillan/.local/bin/xmobar ~/.xmonad/xmobarrc"
    dbus <- D.connectSession
    -- Request access to the DBus name
    D.requestName dbus (D.busName_ "org.xmonad.Log")
        [D.nameAllowReplacement, D.nameReplaceExisting, D.nameDoNotQueue]

    xmonad
     $ docks
     $ def
        { startupHook = setWMName "LG3D"
        , manageHook = manageDocks
                       <+> (className =? "Xfce4-notifyd" --> doIgnore)
                       <+> manageHook def
        , workspaces = myWorkspaces
        , layoutHook = (avoidStruts $ withMobarLayouts)
                       ||| noBorders (fullscreenFull Full)
        , logHook = dynamicLogWithPP (myLogHook dbus)
        , modMask = mod4Mask     -- Rebind Mod to the Windows key
        , terminal = "exec urxvt"
        } `additionalKeys` myKeys


-- Override the PP values as you would otherwise, adding colors etc depending
-- on  the statusbar used
-- Colours
colorForeground = "$$FOREGROUND$$"
colorBackground = "$$BACKGROUND$$"
colorAccent     = "$$ACCENT$$"
colorLine       = "$$LINE$$"
colorBorder     = "$$BORDER$$"
colorHighlight  = "$$HIGHLIGHT$$"
colorIcon       = "$$ICON$$"

myAddSpaces :: Int -> String -> String
myAddSpaces len str = sstr ++ replicate (len - length sstr) ' '
  where
    sstr = shorten len str

withColor :: String -> String -> String
withColor c = wrap ("%{F" ++ c ++ "} ") " %{F-}"

myLogHook :: D.Client -> PP
myLogHook dbus = def
    { ppOutput = dbusOutput dbus
    , ppCurrent = withColor colorHighlight
    , ppVisible = withColor colorForeground
    , ppUrgent = withColor colorAccent
    , ppHidden = wrap " " " "
    , ppWsSep = ""
    , ppSep = withColor colorIcon " | "
    , ppTitle = withColor colorIcon . myAddSpaces 50
    }

-- Emit a DBus signal on log updates
dbusOutput :: D.Client -> String -> IO ()
dbusOutput dbus str = do
    let signal = (D.signal objectPath interfaceName memberName) {
            D.signalBody = [D.toVariant $ UTF8.decodeString str]
        }
    D.emit dbus signal
  where
    objectPath = D.objectPath_ "/org/xmonad/Log"
    interfaceName = D.interfaceName_ "org.xmonad.Log"
    memberName = D.memberName_ "Update"