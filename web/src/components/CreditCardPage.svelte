<script lang="ts">
  import { writable } from "svelte/store";
  import { slide, fade, scale } from "svelte/transition";
  import { quintOut } from "svelte/easing";
  import { fetchNui } from "../utils/fetchNui";
  import { Locales, creditCardData, Notify } from "../store/data";

  import card from "../utils/images/card.png";
  import cardDisabled from "../utils/images/card_disabled.png";
  import { onMount } from "svelte";

  let imgRef: any;
  let divRef: any;
  let showPin: boolean = false;
  let isCardDisabled: boolean = false;
  let pinCard = writable("");

  onMount(() => {
    fetchNui("fd_banking:client:fetchCreditCard", {})
      .then((response) => {
        if (response) {
          creditCardData.set(response);
          isCardDisabled = response.isDisabled;
        } else {
          isCardDisabled = true;
        }
      })
      .catch((error) => { });

    imgRef.src = isCardDisabled ? cardDisabled : card;
    setTimeout(() => {
      if (!divRef || !imgRef) return;
      // set same size and pos for div
      divRef.style.width = `${imgRef.clientWidth}px`;
      divRef.style.height = `${imgRef.clientHeight}px`;
      divRef.style.top = `${imgRef.offsetTop}px`;
      divRef.style.left = `${imgRef.offsetLeft}px`;
      divRef.style.position = "absolute";
    }, 1000);
  });

  const resizeImage = () => {
    divRef.style.width = `${imgRef.clientWidth}px`;
    divRef.style.height = `${imgRef.clientHeight}px`;
    divRef.style.top = `${imgRef.offsetTop}px`;
    divRef.style.left = `${imgRef.offsetLeft}px`;
    divRef.style.position = "absolute";
  };

  const pinInput = ({ target }: any) => {
    let value = (target ? target.value : "") as string;
    // remove all non number characters
    value = value.replace(/\D/g, "");
    if (value.length > 5) {
      value = value.slice(0, 5);
    }
    pinCard.set(value);
  }
</script>

<!-- svelte-ignore a11y-label-has-associated-control -->
<div class="relative bg-gray-800 w-full h-full">
  <div
    class="relative top-0 overflow-hidden p-6 text-white w-full h-full"
    in:slide={{ duration: 1000, easing: quintOut }}
    on:animationend={resizeImage}
  >
    <div class="bg-gray-700/20 p-8 rounded-lg shadow-lg border border-blue-200/5 flex flex-col">
      <div class="flex items-center mb-6">
        <i class="fa-duotone fa-credit-card text-3xl text-blue-400 mr-3"></i>
        <h2 class="text-3xl font-bold">{$Locales.credit_card}</h2>
      </div>

      <!-- <div class="w-fit-content mb-8">
        <h2 class="text-3xl font-bold text-blue-200">{$Locales.credit_card}</h2>
      </div> -->

      <div class="w-full flex">
        <div class="w-full flex h-full">
          <img
            alt="card"
            class="w-[725px]"
            bind:this={imgRef}
            in:scale={{ duration: 1000, easing: quintOut }}
          />
          <div
            bind:this={divRef}
            in:fade={{ duration: 500, easing: quintOut, delay: 1000 }}
          >
            <div class="text-6xl font-bold top-80 left-[65px] absolute">
              {$creditCardData.number.replace(/(.{4})/g, "$1 ")}
            </div>
            <div
              class="text-2xl font-bold top-[420px] left-[95px] absolute underline"
            >
              {$creditCardData.name.toUpperCase()}
            </div>
            <div
              class="text-2xl font-bold top-[420px] right-[95px] absolute underline"
            >
              {#if showPin}
                {$creditCardData.pin}
              {:else}
                {Array.from({ length: $creditCardData.pin.length })
                  .map(() => "*")
                  .join("")}
              {/if}
            </div>
          </div>
        </div>

        <div class="p-8 w-1/2 flex flex-col justify-around h-full bg-gray-700 rounded-xl">
          <div class="mb-4 flex items-center justify-center">
            <span class="text-blue-200 font-bold text-xl">
              {$Locales.card_controls}
            </span>
          </div>

          <button
            class="bg-blue-600/10 border border-blue-500 hover:bg-blue-800/50 text-white font-bold py-2 px-4 mt-4 duration-500 rounded-lg cursor-pointer"
            on:click={() => (showPin = !showPin)}
          >
            {showPin ? $Locales.hide_pin : $Locales.show_pin}
          </button>

          <div class="flex flex-row justify-between w-full">
            <input
              type="text"
              class="bg-gray-700/20 border border-blue-500 text-white font-bold py-2 px-4 mt-4 duration-500 rounded-lg focus:outline-none"
              placeholder={$Locales.new_pin}
              bind:value={$pinCard}
              on:change={pinInput}
            />
            <button
              class="bg-blue-600/10 border border-blue-500 hover:bg-blue-800/50 text-white font-bold py-2 px-4 mt-4 duration-500 rounded-lg cursor-pointer"
              on:click={() => {
                fetchNui("fd_banking:client:changePin", {
                  pin: $pinCard,
                })
                  .then((response) => {
                    if (response.success) {
                      const oldData = $creditCardData;
                      oldData.pin = $pinCard;
                      creditCardData.set(oldData);
                    } else {
                      Notify($Locales.pin_change_error_description, $Locales.pin_change_error, "triangle-exclamation");
                    }
                  })
                  .catch((error) => { });
              }}
            >
              {$Locales.change_pin}
            </button>
          </div>

          <button
            class="bg-blue-600/10 border border-blue-500 hover:bg-blue-800/50 text-white font-bold py-2 px-4 mt-4 duration-500 rounded-lg cursor-pointer"
            on:click={() => {
              fetchNui("fd_banking:client:requestCard", {})
              .then((response) => {
                  Notify($Locales.card_requested_description, $Locales.card_requested, "credit-card");
                })
                .catch((error) => {});
            }}
          >
            {$Locales.request_card}
          </button>
          <!-- 
          <button
            class="bg-blue-600/10 border border-blue-500 hover:bg-blue-800/50 text-white font-bold py-2 px-4 mt-4 duration-500 rounded-lg cursor-pointer"
            on:click={() => {
              isCardDisabled = !isCardDisabled;
              imgRef.src = isCardDisabled ? cardDisabled : card;
              if (isCardDisabled) {
                divRef.style.display = "none";
                fetchNui("fd_banking:client:lockCard", {
                  isDisabled: true,
                });
              } else {
                divRef.style.display = "block";
                fetchNui("fd_banking:client:lockCard", {
                  isDisabled: false,
                });
              }
            }}
          >
            {isCardDisabled ? $Locales.unlock_card : $Locales.lock_card}
          </button>
          -->
        </div>
      </div>
    </div>
  </div>
</div>
