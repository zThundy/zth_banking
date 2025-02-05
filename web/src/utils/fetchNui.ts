/**
* @param eventName - The endpoint eventname to target
* @param data - Data you wish to send in the NUI Callback
*
* @return returnData - A promise for the data sent back by the NuiCallbacks CB argument
*/

export function fetchNui<T = any>(
  eventName: string,
  data: unknown = {}
): Promise<T> {
  return new Promise(async (resolve, reject) => {
    try {
      const options = {
        method: "post",
        headers: {
          "Content-Type": "application/json; charset=UTF-8",
        },
        body: JSON.stringify(data),
      };

      const resourceName = (window as any).GetParentResourceName
        ? (window as any).GetParentResourceName()
        : "nui-frame-app";

      fetch(`https://${resourceName}/${eventName}`, options)
        .then(async (resp) => {
          const data = await resp.json();
          resolve(data);
        })
        .catch((err) => {
          reject(err);
        });

      // return await resp.json();
    } catch (e) {
      // console.error(`Failed to send data to ${eventName}`, e.message);
      // return {} as T;
      reject(e);
    }
  });
}
