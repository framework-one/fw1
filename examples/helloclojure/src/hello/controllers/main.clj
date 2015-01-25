(ns hello.controllers.main
  (:require [hello.greet :as greet]))

(defn default [rc]
  (assoc rc :greeting (greet/hello (:name rc "anonymous"))))
