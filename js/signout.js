import { supabase } from "./supabase.js";

// Shows the sign-out button only when someone is signed in.
// Signing out reloads the page so every view updates.
export async function setupSignOut(button) {
  const { data } = await supabase.auth.getSession();
  if (!data.session) return;

  button.hidden = false;
  button.addEventListener("click", async () => {
    button.disabled = true;
    await supabase.auth.signOut();
    location.reload();
  });
}
