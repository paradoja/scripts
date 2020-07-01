#!/usr/bin/env stack
-- stack --resolver global script

{-# LANGUAGE ExtendedDefaultRules #-}
{-# LANGUAGE OverloadedStrings #-}
{-# OPTIONS_GHC -fno-warn-type-defaults #-}

-- This tries to control the execution of different called
-- applications. So using this to call and forget... it's not really
-- working...

import Control.Applicative
import Control.Monad
import Data.List as L
import Data.Text as T
import Shelly
import System.IO

default (T.Text)

newtype PSList = PSList {unPSList :: [Text]}

eval_ = bash_ "eval"

hideSetupWindows = do
  windowInfo <- run "wmctrl" ["-l"]
  let winIds = L.head . T.words <$> T.lines windowInfo
  forM winIds $ \id ->
    run "wmctrl" ["-i", "-r", id, "-t", "9"]

runUnless procs p = unless (alreadyRunning procs p)

ps opts = PSList . T.lines <$> run "ps" opts

alreadyRunning ps p =
  [] /= L.filter (T.isInfixOf p) (unPSList ps)

startXSession = silently $ do
  -- bash_ "xmonad" ["--replace", "&"]
  run_ "xrandr" ["--output", "eDP-1", "--brightness", "0.5"]
  -- sleep 4
  -- hideSetupWindows
  -- bash_ "emacs" ["&"]
  bash "gnome-terminal" ["--", "/bin/sh", "-c", "'ssh-add; zsh -c \"tmux; zsh -i\"'"]
  run_ "feh" ["--bg-scale", "--randomize", "--recursive", "/usr/share/backgrounds/"]

main = do
  hSetBuffering stdout LineBuffering
  -- shelly $ verbosely $ do
  shelly $ do
    run_ "setxkbmap" ["-option", "ctrl:swapcaps"]
    procs <- silently $ ps ["ax"]
    runUnless procs "ssh-agent" $ eval_ ["$(ssh-agent)"]
    runUnless procs "xmonadl" startXSession
