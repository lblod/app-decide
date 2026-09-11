(define-resource scheduled-job ()
  :class (s-prefix "cogs:ScheduledJob")
  :properties `((:creator :url ,(s-prefix "dct:creator"))
                (:created :datetime ,(s-prefix "dct:created"))
                (:modified :datetime ,(s-prefix "dct:modified"))
                (:operation :url ,(s-prefix "task:operation"))  ;;Later consider using proper relation in domain.lisp
                (:title :string ,(s-prefix "dct:title"))
                (:vendor    :url      ,(s-prefix "prov:wasAssociatedWith"))
                (:split-decisions :boolean ,(s-prefix "ext:splitDecisions")))
  :has-one `((cron-schedule :via ,(s-prefix "task:schedule")
                    :as "schedule"))

  :has-many `((scheduled-task :via ,(s-prefix "dct:isPartOf")
                    :inverse t
                    :as "scheduled-tasks"))

  :resource-base (s-url "http://redpencil.data.gift/id/scheduled-job/")
  :features '(include-uri)
  :on-path "scheduled-jobs")

(define-resource scheduled-task ()
  :class (s-prefix "task:ScheduledTask")
  :properties `((:created :datetime ,(s-prefix "dct:created"))
                (:modified :datetime ,(s-prefix "dct:modified"))
                (:operation :url ,(s-prefix "task:operation")) ;;Later consider using proper relation in domain.lisp
                (:index :string ,(s-prefix "task:index")))

  :has-one `((scheduled-job :via ,(s-prefix "dct:isPartOf")
                    :as "scheduled-job"))

  :has-many `((scheduled-task :via ,(s-prefix "cogs:dependsOn")
                    :as "parent-tasks")
              (data-container :via ,(s-prefix "task:inputContainer")
                    :as "input-containers"))

  :resource-base (s-url "http://redpencil.data.gift/id/scheduled-task/")
  :features '(include-uri)
  :on-path "scheduled-tasks")


(define-resource cron-schedule ()
  :class (s-prefix "task:CronSchedule")
  :properties `((:repeat-frequency :string ,(s-prefix "schema:repeatFrequency")))

  :resource-base (s-url "http://redpencil.data.gift/id/cron-schedule/")
  :features '(include-uri)
  :on-path "cron-schedules")