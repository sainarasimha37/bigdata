local utils = import 'utils.libsonnet';

function(config) (
  [
    {
      apiVersion: 'apps/v1',
      kind: 'Deployment',
      metadata: {
        name: 'rabbitmq',
        labels: {
          app: 'auctus',
          what: 'rabbitmq',
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
            what: 'rabbitmq',
          },
        },
        template: {
          metadata: {
            labels: {
              app: 'auctus',
              what: 'rabbitmq',
            },
          },
          spec: {
            securityContext: {
              runAsNonRoot: true,
            },
            containers: [
              {
                name: 'rabbitmq',
                image: 'quay.io/remram44/rabbitmq:3.8.11',
                securityContext: {
                  runAsUser: 999,
                },
                env: [
                  {
                    name: 'RABBITMQ_DEFAULT_USER',
                    valueFrom: {
                      secretKeyRef: {
                        name: 'secrets',
                        key: 'amqp.user',
                      },
                    },
                  },
                  {
                    name: 'RABBITMQ_DEFAULT_PASS',
                    valueFrom: {
                      secretKeyRef: {
                        name: 'secrets',
                        key: 'amqp.password',
                      },
                    },
                  },
                ],
                ports: [
                  {
                    containerPort: 5672,
                  },
                  {
                    containerPort: 15672,
                  },
                  {
                    containerPort: 15692,
                  },
                ],
              },
            ],
          } + utils.affinity(node=config.db_node_label.rabbitmq),
        },
      },
    },
    {
      apiVersion: 'v1',
      kind: 'Service',
      metadata: {
        name: 'rabbitmq',
        labels: {
          app: 'auctus',
          what: 'rabbitmq',
        },
      },
      spec: {
        selector: {
          app: 'auctus',
          what: 'rabbitmq',
        },
        ports: [
          {
            protocol: 'TCP',
            port: 5672,
          },
        ],
      },
    },
    {
      apiVersion: 'v1',
      kind: 'Service',
      metadata: {
        name: 'rabbitmq-management',
        labels: {
          app: 'auctus',
          what: 'rabbitmq',
        },
      },
      spec: {
        selector: {
          app: 'auctus',
          what: 'rabbitmq',
        },
        ports: [
          {
            protocol: 'TCP',
            port: 15672,
          },
        ],
      },
    },
  ]
)