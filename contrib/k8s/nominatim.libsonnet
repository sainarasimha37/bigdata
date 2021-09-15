local utils = import 'utils.libsonnet';

function(
  config,
  data_url,
) (
  [
    config.kube('v1', 'PersistentVolumeClaim', {
      metadata: {
        name: 'nominatim',
      },
      spec: {
        storageClassName: config.storage_class,
        accessModes: [
          'ReadWriteOnce',
        ],
        resources: {
          requests: {
            storage: '250Gi',
          },
        },
      },
    }),
    config.kube('v1', 'Service', {
      metadata: {
        name: 'nominatim',
        labels: {
          app: 'auctus',
          what: 'nominatim',
        },
      },
      spec: {
        selector: {
          app: 'auctus',
          what: 'nominatim',
        },
        ports: [
          {
            protocol: 'TCP',
            port: 8080,
          },
        ],
      },
    }),
    config.kube('apps/v1', 'Deployment', {
      metadata: {
        name: 'nominatim',
        labels: {
          app: 'auctus',
          what: 'nominatim',
        },
      },
      spec: {
        replicas: 1,
        strategy: {
          type: 'Recreate',
        },
        selector: {
          matchLabels: {
            app: 'auctus',
            what: 'nominatim',
          },
        },
        template: {
          metadata: {
            labels: {
              app: 'auctus',
              what: 'nominatim',
            },
          },
          spec: {
            initContainers: [
              {
                name: 'download-data',
                image: 'quay.io/remram44/nominatim:3.4',
                command: [
                  'sh',
                  '-c',
                  'if ! [ -d /data/base ]; then\n  curl -Ls %s | tar -C /data --strip-components=1 -xf -\nfi\n' % data_url,
                ],
                volumeMounts: [
                  {
                    mountPath: '/data',
                    name: 'data',
                  },
                ],
              },
            ],
            containers: [
              {
                name: 'nominatim',
                image: 'quay.io/remram44/nominatim:3.4',
                args: [
                  'bash',
                  '/app/start.sh',
                ],
                ports: [
                  {
                    containerPort: 5432,
                  },
                  {
                    containerPort: 8080,
                  },
                ],
                volumeMounts: [
                  {
                    mountPath: '/var/lib/postgresql/11/main',
                    name: 'data',
                  },
                ],
              },
            ],
            volumes: [
              {
                name: 'data',
                persistentVolumeClaim: {
                  claimName: 'nominatim',
                },
              },
            ],
          } + utils.affinity(node=config.db_node_label.nominatim),
        },
      },
    }),
  ]
)
