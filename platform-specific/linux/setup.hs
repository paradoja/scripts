#!/usr/bin/env stack
-- stack --resolver global script
-- stack ghc -- -O2 -threaded -x hs =( tail -n $(awk 'END { print NR-1 }' $1.hs) $1.hs) -o ${1%hs}
{-# LANGUAGE OverloadedStrings #-}

import Turtle
import qualified Control.Foldl as F

run x = shell x empty

hideSetupWindows = do
  window <- inshell "wmctrl -l | awk '{print $1}'" empty
  run $ format ("wmctrl -i -r"%s%"-t 9") $ lineToText window

alreadyRunning prs = do
  m <- fold (cat $ map (\pr -> grep (has pr) $ inshell "ps ax" empty) prs) F.length
  return $ if m == 0
    then ExitFailure 1
    else ExitSuccess

runUnless pr ex = alreadyRunning pr .||. ex

startXSession = do
  run "xmonad --replace &"
  run "xrandr --output eDP-1 --brightness 0.5"
  sh $ do sleep 2
          hideSetupWindows
  run "emacs &"
  run "gnome-terminal -- /bin/sh -c 'ssh-add; zsh -c \"tmux; zsh -i\"'"
  run "feh --bg-scale --randomize --recursive /usr/share/backgrounds/"

main = do
  run "setxkbmap -option ctrl:swapcaps"
  runUnless ["ssh-agent"] $ run "eval $(ssh-agent -s)"
  runUnless ["xmonad"] startXSession
