;; very minimal Boot build file: for use with cfmljure we do not
;; need any pom / jar information, just the dependencies and a
;; matching boot.properties file
(set-env! :resource-paths #{"src"}
          :dependencies '[[org.clojure/clojure "1.7.0"]])
