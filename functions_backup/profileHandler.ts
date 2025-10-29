      import { defineFunction } from "@aws-amplify/backend";

      export const profileHandler = defineFunction({
        name: "profile-handler",
        entry: "./handler.ts",
      });