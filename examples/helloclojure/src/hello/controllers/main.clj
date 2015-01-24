(ns hello.controllers.main)

(defn default [rc]
  (assoc rc :greeting (str "Hello " (:name rc "anonymous") "!")))
