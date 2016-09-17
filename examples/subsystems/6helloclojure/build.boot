;; very minimal Boot build file: for use with cfmljure we do not
;; need any pom / jar information, just the dependencies and a
;; matching boot.properties file
(set-env! :resource-paths #{"src"}
          :source-paths #{"test"}
          :dependencies '[[org.clojure/clojure "1.7.0"]
                          [adzerk/boot-test "1.0.7"]])

(require '[adzerk.boot-test :refer [test]])
