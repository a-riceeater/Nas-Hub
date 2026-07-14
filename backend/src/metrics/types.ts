import { z } from "zod";
export const metricSchema=z.object({timestamp:z.number(),cpuPercent:z.number().nullable(),perCore:z.array(z.number()),load1:z.number(),load5:z.number(),load15:z.number(),ramTotal:z.number(),ramUsed:z.number(),ramAvailable:z.number(),ramPercent:z.number(),swapTotal:z.number(),swapUsed:z.number(),diskTotal:z.number(),diskUsed:z.number(),diskAvailable:z.number(),diskPercent:z.number().nullable(),diskReadBps:z.number().nullable(),diskWriteBps:z.number().nullable(),networkRxBps:z.number().nullable(),networkTxBps:z.number().nullable(),uptime:z.number(),processCount:z.number(),temperature:z.number().nullable(),bootTime:z.number()});
export type Metric=z.infer<typeof metricSchema>;

