(import (fetchTarball {
  url = "https://github.com/edolstra/flake-compat/archive/master.zip";
  sha256 = "0x2jn3vrawwv9xp15674wjz9pixwjyj3j771izayl962zziivbx2";
}) { src = ./.; }).defaultNix
