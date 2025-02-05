<script lang="ts">
  import { writable } from "svelte/store";
  import { slide, scale } from "svelte/transition";
  import { quintOut } from "svelte/easing";
  import { fetchNui } from "../utils/fetchNui";
  import {
    Notify,
    Locales,
    companyData,
    bankBalance,
    bankBalanceMex,
  } from "../store/data";
  import { floorToTwoDecimals } from "../store/methods";
  import { onMount } from "svelte";

  let showModal = writable(false);
  let modalIsWithdraw = writable(false);
  let modalIsDeposit = writable(false);
  let inputAmount = writable(0);
  let selectedCurrency = writable("USD");

  onMount(() => {
    fetchNui("fd_banking:client:fetchCompanyInfo", {})
      .then((company) => {
        if (!company.success) { return; }
        company.balance = floorToTwoDecimals(company.balance);
        companyData.set(company);
      })
      .catch((error) => {
        console.error(error);
      });
  })

  const handleButtonClick = (isBoss: boolean, userName: string, userId: string) => {
    let isRemoving = isBoss ? 1 : 0;
    fetchNui("fd_banking:client:toggleCompanyAccess", {
      isRemoving: isRemoving,
      userName: userName,
      userId: userId
    })
      .then((response) => {
        if (!response.success) {
          Notify($Locales.company_access_error_description, $Locales.company_access_error, "triangle-exclamation");
          return;
        }

        // response.users
        companyData.update((company) => {
          company.users = response.users;
          return company;
        });

        if (isBoss) {
          Notify(`${$Locales.company_remove_access_description} ${userName}`, $Locales.company_remove_access, "triangle-exclamation");
        } else {
          Notify(`${$Locales.company_give_access_description} ${userName}`, $Locales.company_give_access, "triangle-exclamation");
        }
      })
      .catch((error) => {
        console.error(error);
      });
  }

  const handleModalSubmit = () => {
    // check if there is any letters in the inputAmount
    if ($inputAmount.toString().match(/[a-z]/i)) {
      Notify($Locales.company_invalid_amount_description, $Locales.company_invalid_amount, "triangle-exclamation");
      return;
    }

    if ($inputAmount <= 0) {
      Notify($Locales.company_invalid_amount_description, $Locales.company_invalid_amount, "triangle-exclamation");
      return;
    }

    if ($modalIsDeposit) {
      fetchNui("fd_banking:client:depositCompany", {
        amount: $inputAmount,
        currency: $selectedCurrency
      })
        .then((response) => {
          if (!response.success) {
            Notify($Locales.company_deposit_error_description, $Locales.company_deposit_error, "triangle-exclamation");
            return;
          }
          Notify($Locales.company_deposit_success_description, $Locales.company_deposit_success, "check-circle");
          companyData.update((company) => {
            company.balance = response.balance;
            company.balanceMex = response.balanceMex;
            return company;
          });
          selectedCurrency.set("USD");
          bankBalance.set(response.rBalance);
          bankBalanceMex.set(response.rBalanceMex);
        })
        .catch((error) => {
          console.error(error);
        });
    } else if ($modalIsWithdraw) {
      if ($companyData.balance < $inputAmount) {
        Notify($Locales.company_insufficient_funds_description, $Locales.company_insufficient_funds, "triangle-exclamation");
        return;
      }

      fetchNui("fd_banking:client:withdrawCompany", {
        amount: $inputAmount,
        currency: $selectedCurrency
      })
        .then((response) => {
          if (!response.success) {
            Notify($Locales.company_withdraw_error_description, $Locales.company_withdraw_error, "triangle-exclamation");
            return;
          }
          Notify($Locales.company_withdraw_success_description, $Locales.company_withdraw_success, "check-circle");
          companyData.update((company) => {
            company.balance = response.balance;
            company.balanceMex = response.balanceMex;
            return company;
          });
          selectedCurrency.set("USD");
          bankBalance.set(response.rBalance);
          bankBalanceMex.set(response.rBalanceMex);
        })
        .catch((error) => {
          console.error(error);
        });
    }

    inputAmount.set(0)
    showModal.set(false)
  }

  const currencySwitch = ({ target }: any) => {
    selectedCurrency.set(target.value);
  }
</script>

<!-- svelte-ignore a11y-label-has-associated-control -->
<div class="relative bg-gray-800 w-full h-full">
  <div
    class="relative top-0 overflow-hidden p-6 text-white w-full h-full"
    in:slide={{ duration: 1000, easing: quintOut }}
  >
    <div class="bg-gray-700/20 p-8 rounded-lg shadow-lg border border-blue-200/5">
      <div class="flex items-center mb-6">
        <i class="fa-duotone fa-building text-3xl text-blue-400 mr-3"></i>
        <h2 class="text-3xl font-bold">{$Locales.companies}</h2>
      </div>

      <div class="bg-gray-700 rounded-xl p-4 w-full flex flex-col mb-4">
        <div class="text-2xl mb-4 text-blue-200 font-bold">{$Locales.company_info}</div>

        <div class="flex w-full justify-between">
          <div class="rounded-xl bg-gray-600 w-full flex p-4 m-2 flex-col">
            <div class="flex items-center mb-6">
              <i class="fa-duotone fa-file-signature text-xl text-blue-400 mr-3"></i>
              <h2 class="text-xl font-bold text-blue-200">{$Locales.company_name}</h2>
            </div>
            <div class="text-xl font-bold">
              {$companyData.name}
            </div>
          </div>
          <div class="rounded-xl bg-gray-600 w-full flex p-4 m-2 flex-col items-end">
            <div class="flex items-center mb-6">
              <i class="fa-duotone fa-bank text-xl text-blue-400 mr-3"></i>
              <h2 class="text-xl font-bold text-blue-200">{$Locales.company_balance}</h2>
            </div>

            <div class="text-xl font-bold">
              USD {$companyData.balance} / MXN {$companyData.balanceMex}
            </div>
          </div>
        </div>
      </div>

      <div class="bg-gray-700 rounded-xl p-4 w-full flex flex-col mb-4">
        <div class="text-2xl mb-4 text-blue-200 font-bold">{$Locales.company_actions}</div>

        <div class="flex w-full justify-around">
          <div class="w-full p-8">
            <button
              class="bg-blue-600/10 border border-blue-500 hover:bg-blue-800/50 text-white font-bold py-2 px-4 mt-4 duration-500 rounded-lg cursor-pointer w-full"
              on:click={() => {
                modalIsDeposit.set(true)
                modalIsWithdraw.set(false)
                showModal.set(true)
              }}
            >
              {$Locales.deposit}
            </button>
          </div>

          <div class="w-full p-8">
            <button
              class="bg-blue-600/10 border border-blue-500 hover:bg-blue-800/50 text-white font-bold py-2 px-4 mt-4 duration-500 rounded-lg cursor-pointer w-full"
              on:click={() => {
                modalIsDeposit.set(false)
                modalIsWithdraw.set(true)
                showModal.set(true)
              }}
            >
              {$Locales.withdraw}
            </button>
          </div>
        </div>
      </div>

      <div class="bg-gray-700 rounded-xl p-4 w-full flex flex-col mb-4">
        <div class="text-2xl mb-4 text-blue-200 font-bold">{$Locales.company_manage_users}</div>

        <div class="flex w-full justify-around">
          <div class="space-y-4 border border-dashed border-blue-400 rounded-lg p-4 w-full overflow-y-auto h-64">
            {#each $companyData.users as user}
              <div class="flex items center justify-between">
                <div class="flex items-center">
                  {#if user.isboss}
                    <i class="fa-duotone fa-user text-xl text-green-400 mr-3"></i>
                  {:else}
                    <i class="fa-duotone fa-user text-xl text-blue-400 mr-3"></i>
                  {/if}
                  <div class="text-xl font-bold text-blue-200">
                    {user.name}
                  </div>
                </div>

                <div class="flex items">
                  {#if user.isboss}
                    <button
                      class="bg-red-600/10 border border-red-500 hover:bg-red-800/50 text-white font-bold py-2 px-4 ml-2 mr-2 duration-500 rounded-lg cursor-pointer"
                      on:click={() => handleButtonClick(user.isboss, user.name, user.id)}
                    >
                      {$Locales.company_remove_access}
                    </button>
                  {:else}
                    <button
                      class="bg-blue-600/10 border border-blue-500 hover:bg-blue-800/50 text-white font-bold py-2 px-4 ml-2 mr-2 duration-500 rounded-lg cursor-pointer"
                      on:click={() => handleButtonClick(user.isboss, user.name, user.id)}
                    >
                      {$Locales.company_give_access}
                    </button>
                  {/if}
                </div>
              </div>
              <div class="border-b border-gray-600"></div>
            {/each}
          </div>
        </div>
      </div>
    </div>
  </div>
  
  {#if $showModal}
  <div class="fixed inset-0 flex items-center justify-center bg-black bg-opacity-50 z-50">
    <div
      class="bg-gray-700 p-8 rounded-lg shadow-lg w-96 flex flex-col justify-around h-[calc(100%-48rem)] w-[calc(100%-88rem)]"
      in:scale={{ duration: 250, easing: quintOut }}
      out:scale={{ duration: 250, easing: quintOut }}
    >
      <div class="flex items-center">
        <i class="fa-duotone fa-question-circle text-3xl text-blue-400 mr-3"></i>
        <h2 class="text-2xl text-blue-200 font-bold">
          {#if $modalIsDeposit}
            {$Locales.deposit}
          {:else}
            {$Locales.withdraw}
          {/if}
        </h2>
      </div>
      <div class="text-gray-300 flex flex-col">
        {#if $modalIsDeposit}
          <span>{$Locales.company_deposit_description}</span>
          <span>{$Locales.company_deposit_input_description}</span>
        {:else}
          <span>{$Locales.company_withdraw_description}</span>
          <span>{$Locales.company_withdraw_input_description}</span>
        {/if}
      </div>

      <div class="flex items-center">
        <input
          type="text"
          class="bg-gray-700/20 border border-blue-500 text-white font-bold py-2 px-4 duration-500 rounded-lg w-full focus:outline-none"
          placeholder="{$Locales.amount}"
          bind:value={$inputAmount}
        />
        <select
          class="bg-gray-700/50 text-white pl-2 pr-4 py-3 border border-blue-200/10 rounded-lg focus:outline-none
            focus:border-blue-400/50 transition-colors duration-500 ml-2"
            on:change={currencySwitch}
        >
          <option value={"USD"}>USD</option>
          <option value={"MXN"}>MXN</option>
        </select>
      </div>

      <div class="flex justify-between items-center">
        <button
          class="flex items-center bg-red-600 hover:bg-red-700 text-white py-2 px-4 rounded focus:outline-none"
          on:click={() => showModal.set(false)}
        >
          <i class="fa-duotone fa-times-circle mr-2"></i>{$Locales.cancel}
        </button>
        <button
          class="flex items-center bg-blue-600 hover:bg-blue-700 text-white py-2 px-4 rounded focus:outline-none"
          on:click={handleModalSubmit}
        >
          <i class="fa-duotone fa-check-circle mr-2"></i>{$Locales.confirm}
        </button>
      </div>
    </div>
  </div>
  {/if}
</div>
