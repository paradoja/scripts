#!/usr/bin/env stack
-- stack --resolver global script

{-# LANGUAGE ExtendedDefaultRules #-}
{-# LANGUAGE OverloadedStrings #-}
{-# OPTIONS_GHC -fno-warn-type-defaults #-}

import Control.Monad
import Data.List as L
import Data.Text as T
import Shelly
import System.IO

default (T.Text)

hideSetupWindows = do
  windowInfo <- run "wmctrl" ["-l"]
  let winIds = fmap (L.head . T.words) $ T.lines windowInfo
  forM winIds $ \id ->
    run "wmctrl" ["-i", "-r", id, "-t", "9"]

runUnless procs p ex =
  when (alreadyRunning p procs) $ silently ex

alreadyRunning ps p = [] /= (L.filter (T.isInfixOf p) $ T.lines ps)

startXSession = silently $ do
  run_ "xmonad" ["--replace", "&"]
  run_ "xrandr" ["--output", "eDP-1", "--brightness", "0.5"]
  sleep 4
  hideSetupWindows
  run_ "emacs" ["&"]
  run_ "gnome-terminal" ["--", "/bin/sh", "-c", "'ssh-add; zsh -c \"tmux; zsh -i\"'"]
  run_ "feh" ["--bg-scale", "--randomize", "--recursive", "/usr/share/backgrounds/"]

main = do
  hSetBuffering stdout LineBuffering
  -- shelly $ verbosely $ do
  shelly $ do
    run_ "setxkbmap" ["-option", "ctrl:swapcaps"]
    procs <- silently $ run "ps" ["ax"]
    runUnless procs "ssh-agent" $ run_ "eval" ["$(sshagent)"]
    runUnless procs "xmonad" startXSession
