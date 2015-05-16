(ns hello.services.greeter
  (:require [hello.greet :as greet]))

(defn greetings [s] (greet/hello (str s "!")))
